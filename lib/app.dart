import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/routing/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gam3ya',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      locale: kReleaseMode ? null : DevicePreview.locale(context),
      builder: kReleaseMode ? null : DevicePreview.appBuilder,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
      ),
    );
  }
}
