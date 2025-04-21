import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/provider/product_provider.dart';
import 'package:provider/provider.dart';
import 'controllers/theme_controller.dart';
import 'views/screens/Admin/admin_dashboard.dart';
import 'views/screens/Customer/login_screen.dart';
import 'views/screens/Customer/register_screen.dart';
import 'views/screens/Customer/wlscreen.dart';
import 'views/screens/Customer/profile_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  // Initialize GetStorage
  await GetStorage.init();

  // Run App
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProductProvider()),  // ✅ Corrected Placement
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeController themeController = Get.put(ThemeController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      builder: EasyLoading.init(),
      home: ShoppingScreen(),
    ));
  }
}
