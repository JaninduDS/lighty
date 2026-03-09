import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io'; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // <-- Added for offline sync

import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/locale_provider.dart';
import 'features/map/presentation/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://gnwhjfxtmgqofhpujlem.supabase.co/',
    anonKey: 'sb_publishable_00aBOF1uF__Kod3xjZkGxQ_osPncgTn',
  );

  // Initialize Firebase
  if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox<List<dynamic>>('guest_reports');

  // ==========================================
  // --- OFFLINE SYNC CHECK ---
  // ==========================================
  final syncBox = await Hive.openBox<List<dynamic>>('offline_sync');
  final pendingResolutions = syncBox.get('pending_resolutions', defaultValue: []) ?? [];
  
  if (pendingResolutions.isNotEmpty) {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        for (var item in pendingResolutions) {
          // Handle both old String format and new Map format gracefully
          if (item is String) {
            await Supabase.instance.client.from('reports').update({'status': 'Resolved'}).eq('id', item);
          } else if (item is Map) {
            await Supabase.instance.client.from('reports').update({'status': 'Resolved'}).eq('id', item['reportId']);
            await Supabase.instance.client.from('poles').update({'status': 'Working'}).eq('id', item['poleId']);
          }
        }
        await syncBox.put('pending_resolutions', []);
        debugPrint('Successfully synced ${pendingResolutions.length} offline tasks!');
      } catch (e) {
        debugPrint('Failed to sync offline tasks: $e');
      }
    }
  }
  // ==========================================

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // Reverted back to standard MaterialApp
    return MaterialApp(
      title: 'Lumina Lanka',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: themeMode,               
      theme: AppTheme.lightTheme,         
      darkTheme: AppTheme.darkTheme,      
      themeAnimationDuration: Duration.zero, 
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          ),
          child: child!,
        );
      },
      home: MapScreen(),
    );
  }
}
