import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/repositories/places_repository.dart';
import 'package:smart_ar_navigation/repositories/route_repository.dart';
import 'package:smart_ar_navigation/services/ar_service.dart';
import 'package:smart_ar_navigation/services/location_service.dart';
import 'package:smart_ar_navigation/viewmodels/ar_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/settings_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/ar_navigation_screen.dart';
import 'package:smart_ar_navigation/views/screens/home_screen.dart';
import 'package:smart_ar_navigation/views/screens/settings_screen.dart';
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

        // ── ViewModels (ChangeNotifier, created in dependency order) ──

        // ARViewModel only needs ARService
        ChangeNotifierProvider<ARViewModel>(
          create: (ctx) => ARViewModel(
            arService: ctx.read<ARService>(),
          ),
        ),

        // NavigationViewModel needs ARViewModel + services + repository
        ChangeNotifierProvider<NavigationViewModel>(
          create: (ctx) => NavigationViewModel(
            routeRepository: ctx.read<RouteRepository>(),
            locationService: ctx.read<LocationService>(),
            arService: ctx.read<ARService>(),
            arViewModel: ctx.read<ARViewModel>(),
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
          ),
        ),

        // SettingsViewModel — no external dependencies, persists via shared_preferences
        ChangeNotifierProvider<SettingsViewModel>(
          create: (_) => SettingsViewModel(),
        ),

        // SavedPlacesViewModel — persists Home / Work / Favourite via shared_preferences
        ChangeNotifierProvider<SavedPlacesViewModel>(
          create: (ctx) => SavedPlacesViewModel(
            placesRepository: ctx.read<PlacesRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/home': (_) => const HomeScreen(),
          '/ar-navigation': (_) => const ARNavigationScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    );
  }
}
