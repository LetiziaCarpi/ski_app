import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../controllers/weather_controller.dart';
import '../controllers/connect_controller.dart';
import '../../core/values/app_colors.dart';
import '../../routes/app_pages.dart';
import 'painters.dart';

class WeatherView extends GetView<WeatherController> {
  const WeatherView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject ConnectController to access IoT data
    final connectController = Get.find<ConnectController>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.purpleLight, AppColors.purpleDark],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed(Routes.connect),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Go to Connection'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (Platform.isMacOS) {
                            Get.snackbar(
                              'Unavailable',
                              'Map is not supported on macOS',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.black54,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          Get.toNamed(Routes.map);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Go to Map'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStatusBar(),
                _buildHeader(),
                const SizedBox(height: 30),
                _buildQuickStats(),
                const SizedBox(height: 20),
                _buildSlopeStatus(),
                const SizedBox(height: 20),
                _buildConditionReport(),
                const SizedBox(height: 20),
                _buildEnvCards(),
                const SizedBox(height: 20),
                _buildHourlyForecast(),
                const SizedBox(height: 20),
                _buildResortInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return const SizedBox.shrink();
  }

  Widget _buildHeader() {
    final connectController = Get.find<ConnectController>();
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(
              () => Text(
                controller.location.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.location_on_outlined,
              color: Colors.white70,
              size: 28,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Obx(
          () => Text(
            connectController.isConnected.value
                ? '${connectController.helmetTemp.value.toStringAsFixed(1)}°'
                : '${controller.temperature.value}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 120,
              fontWeight: FontWeight.w300,
              height: 1.0,
              letterSpacing: -5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wb_cloudy, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Obx(
              () => Text(
                connectController.isConnected.value
                    ? 'Helmet Live'
                    : controller.condition.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            'H:${controller.highTemp.value}° L:${controller.lowTemp.value}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final connectController = Get.find<ConnectController>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF291942), // Dark purple card background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xff8A8F93)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _buildStatItem(
                Icons.water_drop,
                connectController.isConnected.value
                    ? '${connectController.helmetHumidity.value}%'
                    : '${controller.humidity.value}%',
                connectController.isConnected.value ? 'Helmet Hum' : 'Humidity',
              ),
            ),
          ),
          Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              Icons.flash_on, // Matching the lightning bolt icon from image
              '${controller.windSpeed.value} m/s',
              'Wind Speed',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlopeStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF291942), // Dark purple card background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xff8A8F93)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Slope Status',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.3), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => Text(
                  'Slope: ${controller.slopeName.value}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E4E45), // Dark green bg
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4DB6AC)),
                  ),
                  child: const Center(
                    child: Text(
                      'The slope is currently\nsafe for skiing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 140, // Slightly wider for better proportions
                height: 90,
                child: CustomPaint(
                  painter: ArcGaugePainter(score: controller.safetyScore.value),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 10,
                      ), // Offset to fit under the arch
                      Obx(
                        () => Text(
                          '${controller.safetyScore.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36, // Larger font
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Extreme Safe',
                        style: TextStyle(
                          color: Colors.white, // Pure white
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionReport() {
    final connectController = Get.find<ConnectController>();
    return Obx(() {
      bool isFalling = connectController.helmetFall.value;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFalling
              ? Colors.red.withOpacity(0.8)
              : const Color(0xFF291942), // Exact match
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xff8A8F93)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Condition Report',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (isFalling)
                  const Icon(Icons.warning, color: Colors.white, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 20),
            if (isFalling)
              Center(
                child: Text(
                  'FALL DETECTED!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              _buildConditionGrid(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFalling
                      ? Colors.white
                      : const Color(
                          0xFFB71C1C,
                        ).withValues(alpha: 0.8), // Muted deep red
                  foregroundColor: isFalling ? Colors.red : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isFalling ? 'CANCEL ALERT' : 'Request Emergency Assistance',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                isFalling
                    ? 'Emergency contacts will be notified in 30s.'
                    : 'Conditions are stable with low risk at this time.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildConditionGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildConditionItem(
                Icons.people_outline,
                'People on Slope',
                'Not Crowded',
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildConditionItem(
                  Icons.local_hospital_outlined, // Ambulance icon approximation
                  'Accidents Reported',
                  '0 incidents',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildConditionItem(
                Icons.visibility_outlined,
                'Visibility (Fog):',
                'Good visibility',
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildConditionItem(
                  Icons.flash_on,
                  'Lift Accessibility',
                  'No Queue',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnvCards() {
    final connectController = Get.find<ConnectController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Obx(
            () => Container(
              height: 170,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF291942), // Exact background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xff8A8F93)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connectController.isConnected.value
                        ? 'Light Level'
                        : 'UV Index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    connectController.isConnected.value
                        ? '${connectController.helmetLux.value}'
                        : '0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    connectController.isConnected.value ? 'Lux' : 'Low',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // // Colored gradient line removed
                  // Container(
                  //   height: 5,
                  //   width: double.infinity,
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(2),
                  //     gradient: const LinearGradient(
                  //       colors: [
                  //         Colors.green,
                  //         Colors.yellow,
                  //         Colors.red,
                  //         Colors.purple,
                  //       ],
                  //     ),
                  //   ),
                  //   child: Stack(
                  //     alignment: Alignment.centerLeft,
                  //     children: [
                  //       Container(
                  //         margin: const EdgeInsets.only(
                  //           left: 0,
                  //         ),
                  //         width: 4,
                  //         height: 4,
                  //         decoration: const BoxDecoration(
                  //           color: Colors.white,
                  //           shape: BoxShape.circle,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 12),
                  /*Text(
                    connectController.isConnected.value
                        ? 'Ambient light measured\nby helmet sensor.'
                        : 'Low for the rest\nof the day.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),*/
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              Container(
                height: 80, // Taller card
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xff8A8F93)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Rain',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.water_drop,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.water_drop,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.water_drop_outlined,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.water_drop_outlined,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Text(
                      '2.8h',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10), // Tighter spacing
              Container(
                height: 80,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xff8A8F93)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Wind Scale',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Text(
                          '2 ~ 4',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            width: 60, // Approximate progress
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Colors.grey],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Positioned(
                            left: 55,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff8A8F93)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cloudy conditions from 1AM-9AM, with\nshowers expected at 9AM.',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: controller.hourlyForecast.map((item) {
              return Container(
                width: 58, // Fixed width for uniformity
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2146), // Dark purple inner card
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      item['time'].toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      _getWeatherIcon(item['icon'].toString()),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item['temp']}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String iconName) {
    switch (iconName) {
      case 'cloudy':
        return Icons.wb_cloudy_outlined;
      case 'rain':
        return Icons.water_drop_outlined;
      case 'rain_heavy':
        return Icons.tsunami; // Approximation for heavy rain
      case 'storm':
        return Icons.thunderstorm_outlined;
      case 'rain_sun':
        return Icons.wb_sunny_outlined; // Approximation
      default:
        return Icons.cloud_outlined;
    }
  }

  Widget _buildResortInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff8A8F93)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resort Information',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_outline, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'People on Slope',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              Text(
                '1,240', // Format nicely
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildVisibilitySection(),
          const SizedBox(height: 24),
          _buildLiftStatusSection(),
        ],
      ),
    );
  }

  Widget _buildVisibilitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2146), // Dark purple inner card
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visibility by Slope',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 16),
          ...controller.slopeVisibility.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      item['name'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      item['status'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green,
                            Colors.yellow,
                            _getStatusColor(item['status'] as String),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Poor':
        return const Color(0xFFEF5350); // Red
      case 'Fair':
        return const Color(0xFFFFEE58); // Yellow
      case 'Good':
        return const Color(0xFF66BB6A); // Green
      default:
        return Colors.blueAccent;
    }
  }

  Widget _buildLiftStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2146), // Dark purple inner card
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ski Lift Status',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 16),
          ...controller.liftStatus.map((item) {
            final isOpen = item['isOpen'] as bool;
            final color = isOpen
                ? (item['status'] == 'Partially Open'
                      ? const Color(0xFFFFB74D) // Orange
                      : const Color(0xFF66BB6A)) // Green
                : const Color(0xFFEF5350); // Red

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            item['status'] as String,
                            style: TextStyle(color: color, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'Queue: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            item['queue'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
