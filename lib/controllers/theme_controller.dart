import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final GetStorage _storage = GetStorage();
  late RxBool isDarkMode;

  @override
  void onInit() {
    super.onInit();
    isDarkMode = RxBool(_storage.read('isDarkMode') ?? false);
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    _storage.write('isDarkMode', isDarkMode.value);
  }
}
