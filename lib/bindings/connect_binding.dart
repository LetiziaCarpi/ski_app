import 'package:get/get.dart';
import '../controllers/connect_controller.dart';

class ConnectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConnectController>(() => ConnectController());
  }
}
