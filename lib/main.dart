import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'models/models.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';
import 'services/xtream_service.dart';
import 'services/m3u_service.dart';
import 'services/recording_service.dart';

import 'screens/account_setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize libmpv core for hardware-accelerated video decoding
  MediaKit.ensureInitialized();

  // Initialize Services
  final storageService = StorageService();
  await storageService.init();

  final xtreamService = XtreamService();
  final m3uService = M3uService();
  final recordingService = RecordingService();

  // Check saved account
  final savedAccount = storageService.getActiveAccount();
  if (savedAccount != null) {
    xtreamService.setAccount(savedAccount);
  }

  // Force landscape orientation on TVs/tablets
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(
            storageService: storageService,
            xtreamService: xtreamService,
            m3uService: m3uService,
            recordingService: recordingService,
          )..loadXtreamData(),
        ),
      ],
      child: VeloxTvApp(hasSavedAccount: savedAccount != null),
    ),
  );
}

class VeloxTvApp extends StatelessWidget {
  final bool hasSavedAccount;

  const VeloxTvApp({super.key, required this.hasSavedAccount});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeloxTV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF7C4DFF),
          surface: Color(0xFF171B26),
        ),
        fontFamily: 'Roboto',
      ),
      home: hasSavedAccount ? const HomeScreen() : const AccountSetupScreen(),
    );
  }
}
