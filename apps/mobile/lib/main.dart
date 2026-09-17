import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/state/nimmy_controller.dart';
import 'core/theme/app_theme.dart';
import 'services/permissions/permission_service.dart';
import 'services/voice/voice_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: NimmyColors.voidBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final bootstrap = await AppBootstrap.create();
  runApp(NimmyApp(bootstrap: bootstrap));
}

class NimmyApp extends StatelessWidget {
  const NimmyApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NimmyController>.value(
          value: bootstrap.controller,
        ),
        Provider<VoiceService>.value(value: bootstrap.voiceService),
        Provider<PermissionService>.value(value: bootstrap.permissionService),
      ],
      child: MaterialApp.router(
        title: 'Nimmy',
        debugShowCheckedModeBanner: false,
        theme: NimmyTheme.darkTheme,
        routerConfig: NimmyRouter.router,
      ),
    );
  }
}
