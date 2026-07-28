import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/repositories/places_repository.dart';
import 'package:smart_ar_navigation/repositories/recent_places_repository.dart';
import 'package:smart_ar_navigation/repositories/route_repository.dart';
import 'package:smart_ar_navigation/repositories/saved_locations_repository.dart';
import 'package:smart_ar_navigation/services/ar_service.dart';
import 'package:smart_ar_navigation/services/location_service.dart';
import 'package:smart_ar_navigation/services/saved_locations_database.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/recent_places_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_locations_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/settings_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/plan_drive_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/profile_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/ar_navigation_screen.dart';
import 'package:smart_ar_navigation/views/screens/home_screen.dart';
import 'package:smart_ar_navigation/views/screens/plan_drive_screen.dart';
import 'package:smart_ar_navigation/views/screens/profile_screen.dart';
import 'package:smart_ar_navigation/views/screens/settings_screen.dart';
import 'package:smart_ar_navigation/views/screens/debug/arrow_test_screen.dart';
import 'package:smart_ar_navigation/views/screens/splash_screen.dart';

class SmartARNavigationApp extends StatelessWidget {
  const SmartARNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Services & Repositories (no Flutter state, plain Provider) ──
        Provider<LocationService>(
          create: (_) => LocationService(),
        ),
        Provider<ARService>(
          create: (_) => ARService(),
        ),
        Provider<RouteRepository>(
          create: (_) => RouteRepository(),
        ),
        Provider<PlacesRepository>(
          create: (_) => PlacesRepository(),
        ),
        Provider<SavedLocationsDatabase>(
          create: (_) => SavedLocationsDatabase(),
        ),
        Provider<SavedLocationsRepository>(
          create: (ctx) => SavedLocationsRepository(
            db: ctx.read<SavedLocationsDatabase>(),
          ),
        ),
        Provider<RecentPlacesRepository>(
          create: (_) => RecentPlacesRepository(),
        ),

        // ── ViewModels (ChangeNotifier, created in dependency order) ──

        // ProfileViewModel — persists name, email, stats via shared_preferences
        ChangeNotifierProvider<ProfileViewModel>(
          create: (_) => ProfileViewModel(),
        ),

        // SettingsViewModel — no external dependencies, persists via shared_preferences.
        // Registered before NavigationViewModel/MapViewModel so they can read it
        // (avoidTolls) at construction time.
        ChangeNotifierProvider<SettingsViewModel>(
          create: (_) => SettingsViewModel(),
        ),

        // ARViewModel only needs ARService
        ChangeNotifierProvider<ARViewModel>(
          create: (ctx) => ARViewModel(
            arService: ctx.read<ARService>(),
          ),
        ),

        // NavigationViewModel needs ARViewModel + services + repository + ProfileViewModel + SettingsViewModel
        ChangeNotifierProvider<NavigationViewModel>(
          create: (ctx) => NavigationViewModel(
            routeRepository: ctx.read<RouteRepository>(),
            locationService: ctx.read<LocationService>(),
            arService: ctx.read<ARService>(),
            arViewModel: ctx.read<ARViewModel>(),
            profileViewModel: ctx.read<ProfileViewModel>(),
            settingsViewModel: ctx.read<SettingsViewModel>(),
          ),
        ),

        // MapViewModel coordinates GPS stream across both other ViewModels
        ChangeNotifierProvider<MapViewModel>(
          create: (ctx) => MapViewModel(
            locationService: ctx.read<LocationService>(),
            placesRepository: ctx.read<PlacesRepository>(),
            routeRepository: ctx.read<RouteRepository>(),
            navigationViewModel: ctx.read<NavigationViewModel>(),
            arViewModel: ctx.read<ARViewModel>(),
            settingsViewModel: ctx.read<SettingsViewModel>(),
          ),
        ),

        // SavedPlacesViewModel — persists Home / Work / Favourite via shared_preferences
        ChangeNotifierProvider<SavedPlacesViewModel>(
          create: (ctx) => SavedPlacesViewModel(
            placesRepository: ctx.read<PlacesRepository>(),
          ),
        ),

        // SavedLocationsViewModel — persists bookmarked places list via SQLite
        ChangeNotifierProvider<SavedLocationsViewModel>(
          create: (ctx) => SavedLocationsViewModel(
            repo: ctx.read<SavedLocationsRepository>(),
          ),
        ),

        // RecentPlacesViewModel — persists recent search history via shared_preferences
        ChangeNotifierProvider<RecentPlacesViewModel>(
          create: (ctx) => RecentPlacesViewModel(ctx.read<RecentPlacesRepository>())
            ..load(),
        ),

      ],
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
          useMaterial3: true,
        ),
        // Wraps every screen so NavigationViewModel is reachable when the
        // foreground service sends 'stop_navigation' from its isolate.
        builder: (context, child) => _ForegroundTaskListener(child: child!),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/home': (_) => const HomeScreen(),
          '/ar-navigation': (_) => const ARNavigationScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/arrow-test': (_) => const ArrowTestScreen(),
          '/plan-drive': (ctx) => ChangeNotifierProvider(
                create: (c) => PlanDriveViewModel(
                  placesRepository: c.read<PlacesRepository>(),
                  routeRepository: c.read<RouteRepository>(),
                  locationService: c.read<LocationService>(),
                ),
                child: const PlanDriveScreen(),
              ),
        },
      ),
    );
  }
}

// Listens for messages from the foreground task isolate and forwards
// 'stop_navigation' to NavigationViewModel.
class _ForegroundTaskListener extends StatefulWidget {
  const _ForegroundTaskListener({required this.child});
  final Widget child;

  @override
  State<_ForegroundTaskListener> createState() =>
      _ForegroundTaskListenerState();
}

class _ForegroundTaskListenerState extends State<_ForegroundTaskListener> {
  late final NavigationViewModel _navVM;

  @override
  void initState() {
    super.initState();
    _navVM = context.read<NavigationViewModel>();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  void _onTaskData(Object data) {
    if (data == 'service_stopped') {
      _navVM.stopNavigation();
    }
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
