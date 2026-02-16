import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/app_colors.dart';
import '../controllers/connect_controller.dart';

class ConnectView extends GetView<ConnectController> {
  const ConnectView({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 60.0),
                child: Text(
                  'Smart Weather\nHelmet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                    height: 1.2,
                  ),
                ),
              ),

              // Center Connect Button
              GestureDetector(
                onTap: controller.connectToDevice,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow Circles
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    // Main Button
                    Obx(
                      () => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purpleAccent.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: controller.isConnecting.value
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.power_settings_new,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Connect',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Card and Text
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xff8A8F93), width: 1),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            // // Signal Strength
                            // Expanded(
                            //   child: Row(
                            //     children: [
                            //       const Icon(
                            //         Icons.signal_cellular_alt,
                            //         color: Colors.white,
                            //         size: 32,
                            //       ),
                            //       const SizedBox(width: 12),
                            //       Column(
                            //         crossAxisAlignment:
                            //             CrossAxisAlignment.start,
                            //         children: [
                            //           const Text(
                            //             'Signal Strength',
                            //             style: TextStyle(
                            //               color: Colors.white,
                            //               fontSize: 14,
                            //             ),
                            //           ),

                            //           Obx(
                            //             () => Text(
                            //               controller.signalStrength.value,
                            //               style: const TextStyle(
                            //                 color: Colors.white,
                            //                 fontWeight: FontWeight.bold,
                            //                 fontSize: 15,
                            //               ),
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ],
                            //   ),
                            // ),

                            // Divider
                            // VerticalDivider(
                            //   color: Colors.white.withValues(alpha: 0.2),
                            //   thickness: 1,
                            // ),
                            // //  const SizedBox(width: 16),

                            // // Battery Level
                            // Expanded(
                            //   child: Row(
                            //     children: [
                            //       const Icon(
                            //         Icons.battery_std,
                            //         color: Colors.white,
                            //         size: 32,
                            //       ),
                            //       const SizedBox(width: 12),
                            //       Column(
                            //         crossAxisAlignment:
                            //             CrossAxisAlignment.start,
                            //         children: [
                            //           const Text(
                            //             'Battery Level',
                            //             style: TextStyle(
                            //               color: Colors.white,
                            //               fontSize: 14,
                            //             ),
                            //           ),

                            //           Obx(
                            //             () => Text(
                            //               '${controller.batteryLevel.value}%',
                            //               style: const TextStyle(
                            //                 color: Colors.white,
                            //                 fontWeight: FontWeight.bold,
                            //                 fontSize: 15,
                            //               ),
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Make sure the helmet is powered on\nand within range.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
