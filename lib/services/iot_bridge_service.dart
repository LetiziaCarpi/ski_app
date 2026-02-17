import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io'; // Needed for Platform check

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class IotBridgeService {
  // --- MQTT CONFIGURATION ---
  static const String broker = '31.14.140.180';
  static const int port = 1883;
  static const String helmetId = 'helmet_001';
  static const String username = 'skier';
  static const String password = 'IoTskier1';

  final String topicTelemetry = 'unimore_ski/helmets/$helmetId/telemetry';
  final String topicCmd = 'unimore_ski/helmets/$helmetId/cmd';

  // --- BLE CONFIGURATION ---
  final String deviceName = "UNO_R4_BLE";
  final String serviceUuid = "180a";
  final String characteristicUuid = "2a57";

  // --- STATE VARIABLES ---
  MqttServerClient? mqttClient;
  BluetoothDevice? _helmetDevice;
  StreamSubscription? _bleSubscription;
  StreamSubscription? _scanSubscription;
  Position? _currentPosition;
  String _currentPiste = 'P4'; // Logical/fake piste identifier
  Timer? _simulationTimer;
  bool _isScanning = false;

  /// Set the logical piste identifier (faked GPS location name)
  void setPiste(String piste) {
    _currentPiste = piste;
    print("BRIDGE: Piste set to $_currentPiste");
  }

  // --- DATA STREAM ---
  final _sensorDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get sensorData => _sensorDataController.stream;

  /// 1. START BRIDGE
  Future<void> initBridge() async {
    print("BRIDGE: Starting services...");

    // START EVERYTHING IN PARALLEL! Don't block BLE if MQTT is slow.
    _setupLocation();
    _setupMqtt(); // Don't 'await' here, let it work in background

    // Start BLE immediately
    _startBleLogic();
  }

  /// 2. SMART BLE LOGIC
  Future<void> _startBleLogic() async {
    print("BLE: Checking adapter state...");

    // Wait for adapter
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        print("BLE Error: Bluetooth not available.");
        return;
      }
    }

    // STEP A: Check if ALREADY connected (Mac sometimes holds connection)
    List<BluetoothDevice> connected = FlutterBluePlus.connectedDevices;
    for (var d in connected) {
      if (d.platformName == deviceName) {
        print("BLE: Device already connected to system! Connecting...");
        _connectToHelmet(d);
        return;
      }
    }

    // STEP B: If not found, scan
    _startBleScan();
  }

  Future<void> _startBleScan() async {
    if (_isScanning) return;
    _isScanning = true;
    print("BLE: TOTAL Scan started...");

    // 1. Listen to results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // DEBUG PRINT: See what Mac sees
        // print("  📡 Detected: '${r.device.platformName}' [${r.device.remoteId}]");

        // 2. Check NAME (PlatformName or LocalName)
        String name = r.device.platformName;
        if (name.isEmpty) {
          name = r.advertisementData.localName;
        }

        // 3. Check UUID (180a) - Safer than name!
        bool uuidMatch = r.advertisementData.serviceUuids.toString().contains(
          "180a",
        );
        bool nameMatch = name.contains("UNO_R4_BLE");

        if (nameMatch || uuidMatch) {
          print("BLE: MATCH FOUND! ($name) - Connecting...");
          _stopScan();
          _connectToHelmet(r.device);
          break;
        }
      }
    });

    // 4. Start scan WITHOUT FILTERS (To catch everything)
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        // withServices: [Guid("180a")], // Removed for now, search everything
      );
    } catch (e) {
      print("BLE Error StartScan: $e");
    }

    // Timeout
    await Future.delayed(const Duration(seconds: 15));
    if (_helmetDevice == null && _isScanning) {
      print("BLE: TIMEOUT. No device found. Retrying.");
      _stopScan();
    }
  }

  void _stopScan() {
    _isScanning = false;
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  /// 3. ROBUST BLE CONNECTION
  Future<void> _connectToHelmet(BluetoothDevice device) async {
    _helmetDevice = device;
    try {
      print("BLE: Connecting to ${device.remoteId}...");

      // Connection
      await device.connect(autoConnect: false);
      print("BLE: Connected! Discovering services...");

      if (Platform.isAndroid) {
        await device.requestMtu(512);
      }

      // Discover services (Add small delay for stability)
      await Future.delayed(const Duration(milliseconds: 500));
      List<BluetoothService> services = await device.discoverServices();

      bool channelFound = false;

      for (var s in services) {
        // Debug UUID
        // print("Service Found: ${s.uuid}");

        if (s.uuid.toString().toLowerCase().contains(serviceUuid)) {
          for (var c in s.characteristics) {
            // print("  Char Found: ${c.uuid}");
            if (c.uuid.toString().toLowerCase().contains(characteristicUuid)) {
              print("BLE: ✅ Data channel found! Subscribing...");
              await c.setNotifyValue(true);

              _bleSubscription = c.lastValueStream.listen((data) {
                _bridgeData(data);
              });
              channelFound = true;
            }
          }
        }
      }

      if (!channelFound) {
        print("BLE Error: Service/Characteristic NOT found. Wrong UUIDs?");
        // Disconnect to retry cleanly next time
        await device.disconnect();
      }
    } catch (e) {
      print("BLE Error connection: $e");
      // Reset state
      _helmetDevice = null;
    }
  }

  /// 4. DECODING (Unchanged but with extra debug)
  void _bridgeData(List<int> rawData) {
    if (rawData.isEmpty) return;

    try {
      final bytes = Uint8List.fromList(rawData);
      final buffer = ByteData.view(bytes.buffer);

      if (bytes.length < 12) {
        print("BLE Warning: Incomplete packet (${bytes.length} bytes)");
        return;
      }

      double accX = buffer.getInt16(0, Endian.little) / 100.0;
      double accY = buffer.getInt16(2, Endian.little) / 100.0;
      double accZ = buffer.getInt16(4, Endian.little) / 100.0;
      double temp = buffer.getInt16(6, Endian.little) / 10.0;
      int hum = buffer.getUint8(8);
      int lux = buffer.getUint16(9, Endian.little);
      bool isFalling = buffer.getUint8(11) == 1;

      // Payload Creation
      Map<String, dynamic> sensorData = {
        "accel": [accX, accY, accZ],
        "temp": temp,
        "hum": hum,
        "lux": lux,
        "fall": isFalling,
      };

      // Emit to local app
      _sensorDataController.add(sensorData);

      Map<String, dynamic> fullPayload = {
        "helmet_id": helmetId,
        "piste": _currentPiste,
        "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
        "location": {
          "lat": _currentPosition?.latitude ?? 0.0,
          "lon": _currentPosition?.longitude ?? 0.0,
          "alt": _currentPosition?.altitude ?? 0.0,
        },
        "sensors": sensorData,
        "user_status": isFalling ? "FALL" : "OK",
      };

      print("BRIDGE: Data -> Temp: $temp°C, Lux: $lux");

      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(fullPayload));

      if (mqttClient != null &&
          mqttClient!.connectionStatus?.state ==
              MqttConnectionState.connected) {
        mqttClient!.publishMessage(
          topicTelemetry,
          MqttQos.atLeastOnce,
          builder.payload!,
        );
      }
    } catch (e) {
      print("Decoding Error: $e");
    }
  }

  /// 5. MQTT SETUP (Pure Async)
  Future<void> _setupMqtt() async {
    mqttClient = MqttServerClient(broker, 'flutter_client_$helmetId');
    mqttClient!.port = port;
    mqttClient!.keepAlivePeriod = 20;
    mqttClient!.logging(on: false);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_$helmetId')
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    mqttClient!.connectionMessage = connMessage;

    try {
      print('MQTT: Connecting...');
      await mqttClient!.connect();
      print('MQTT: Connected!');
      
      // Subscribe to helmet commands
      mqttClient!.subscribe(topicCmd, MqttQos.atMostOnce);
    } catch (e) {
      print('MQTT Error: $e');
      mqttClient!.disconnect();
    }
  }

  /// 6. GPS SETUP (Anti-crash)
  Future<void> _setupLocation() async {
    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) => _currentPosition = pos,
      onError: (e) => print("GPS Error: $e"),
    );
  }

  /// SIMULATION
  void startSimulation() {
    print("SIMULATION: Starting...");
    _setupLocation();
    if (mqttClient == null ||
        mqttClient!.connectionStatus?.state != MqttConnectionState.connected) {
      _setupMqtt();
    }

    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final builder = BytesBuilder();
      int accVal = 120;
      builder.add([accVal & 0xFF, (accVal >> 8) & 0xFF]);
      builder.add([0, 0]);
      builder.add([0, 0]);
      builder.add([0, 0]);
      builder.add([0, 0]);
      int tempVal = 255;
      builder.add([tempVal & 0xFF, (tempVal >> 8) & 0xFF]);
      builder.addByte(40);
      int luxVal = 300;
      builder.add([luxVal & 0xFF, (luxVal >> 8) & 0xFF]);
      builder.addByte(0);
      // NOTE: We send exactly 12 bytes for simulation
      _bridgeData(builder.toBytes());
    });
  }

  Future<void> stopBridge() async {
    print("BRIDGE: Stopping...");
    _stopScan();
    _simulationTimer?.cancel();
    _bleSubscription?.cancel();
    if (_helmetDevice != null) await _helmetDevice!.disconnect();
    if (mqttClient != null) mqttClient!.disconnect();
  }
}
