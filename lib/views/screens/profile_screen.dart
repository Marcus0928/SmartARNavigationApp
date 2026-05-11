import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/profile_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/place_search_sheet.dart';
import 'package:smart_ar_navigation/views/screens/profile/widgets/profile_header_card.dart';
import 'package:smart_ar_navigation/views/screens/profile/widgets/saved_places_section.dart';
import 'package:smart_ar_navigation/views/screens/profile/widgets/stats_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();

  bool _controllersSynced = false;
  VoidCallback? _vmListener;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<ProfileViewModel>();
      _syncControllers(vm);
      _vmListener = () => _syncControllers(vm);
      vm.addListener(_vmListener!);
    });
  }

  @override
  void dispose() {
    if (_vmListener != null) {
      context.read<ProfileViewModel>().removeListener(_vmListener!);
    }
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _syncControllers(ProfileViewModel vm) {
    if (_controllersSynced) return;
    _controllersSynced = true;
    _nameController.text  = vm.name;
    _emailController.text = vm.email;
  }

  // ── Saved place search ────────────────────────────────────────────────────

  void _showPlaceSearch(SavedPlaceType type, String label) {
    final savedVM = context.read<SavedPlacesViewModel>();
    savedVM.clearSearch();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlaceSearchSheet(type: type, label: label, vm: savedVM),
    ).whenComplete(savedVM.clearSearch);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm      = context.watch<ProfileViewModel>();
    final savedVM = context.watch<SavedPlacesViewModel>();

    final avatarLetter =
        vm.name.isNotEmpty ? vm.name.trim()[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 24),
          ProfileHeaderCard(
            avatarLetter: avatarLetter,
            nameController: _nameController,
            emailController: _emailController,
            isSaving: vm.isSaving,
            onSave: () async {
              await vm.saveProfile(
                _nameController.text,
                _emailController.text,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile saved'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          StatsSection(
            totalDrives: vm.totalDrives,
            totalDistanceKm: vm.totalDistanceKm,
          ),
          const SizedBox(height: 24),
          SavedPlacesSection(
            savedVM: savedVM,
            onShowPlaceSearch: _showPlaceSearch,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
