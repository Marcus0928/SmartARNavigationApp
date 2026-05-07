import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/profile_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/place_search_sheet.dart';

const _kSurface  = Colors.white;
const _kSurface2 = Color(0xFFF5F5F5);
const _kBorder   = Color(0xFFE0E0E0);
const _kMuted    = Color(0xFF9E9E9E);

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

  void _syncControllers(ProfileViewModel vm) {
    if (_controllersSynced) return;
    _controllersSynced = true;
    _nameController.text  = vm.name;
    _emailController.text = vm.email;
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
          _buildProfileHeader(vm, avatarLetter),
          const SizedBox(height: 24),
          _buildStatsSection(vm),
          const SizedBox(height: 24),
          _buildSavedPlacesSection(savedVM),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Profile header ──────────────────────────────────────────────────────────

  Widget _buildProfileHeader(ProfileViewModel vm, String avatarLetter) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
          const SizedBox(height: 28),

          CircleAvatar(
            radius: 44,
            backgroundColor: primaryColor,
            child: Text(
              avatarLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 28),

          _ProfileField(
            label: 'Name',
            controller: _nameController,
            hint: 'Your name',
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 14),

          _ProfileField(
            label: 'Email',
            controller: _emailController,
            hint: 'your@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: vm.isSaving
                  ? null
                  : () async {
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
              child: vm.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Profile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
        ),
      ),
    );
  }

  // ── Stats section ───────────────────────────────────────────────────────────

  Widget _buildStatsSection(ProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('My Stats'),
        const SizedBox(height: 10),
        _Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.flag_rounded,
                    value: vm.totalDrives.toString(),
                    label: 'Drives',
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _StatItem(
                    icon: Icons.route_rounded,
                    value: vm.totalDistanceKm.toStringAsFixed(1),
                    label: 'km driven',
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _StatItem(
                    icon: Icons.star_rounded,
                    value: '–',
                    label: 'Top destination',
                    valueSize: 13,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Saved places section ────────────────────────────────────────────────────

  Widget _buildSavedPlacesSection(SavedPlacesViewModel savedVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Saved Places'),
        const SizedBox(height: 10),
        _Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PlaceRow(
                icon: Icons.home_rounded,
                label: 'Home',
                place: savedVM.home,
                onTap: () => _showPlaceSearch(SavedPlaceType.home, 'Home'),
              ),
              _Separator(),
              _PlaceRow(
                icon: Icons.work_rounded,
                label: 'Work',
                place: savedVM.work,
                onTap: () => _showPlaceSearch(SavedPlaceType.work, 'Work'),
              ),
              _Separator(),
              _AddPlaceRow(
                place: savedVM.favourite,
                onTap: () =>
                    _showPlaceSearch(SavedPlaceType.favourite, 'Favourite'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _kMuted,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
            filled: true,
            fillColor: _kSurface2,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.valueSize = 22,
    this.maxLines = 1,
  });

  final IconData icon;
  final String value;
  final String label;
  final double valueSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: valueSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: _kBorder);
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: _kBorder, indent: 56);
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.icon,
    required this.label,
    required this.place,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final dynamic place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSet = place != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSet
                    ? primaryColor.withValues(alpha: 0.12)
                    : _kSurface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSet ? primaryColor : _kMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isSet
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: _kMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          place!.name as String,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          place!.address as String,
                          style: const TextStyle(
                            color: _kMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : Text(
                      'Set $label',
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: _kMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlaceRow extends StatelessWidget {
  const _AddPlaceRow({required this.place, required this.onTap});

  final dynamic place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSet = place != null;

    if (isSet) {
      return _PlaceRow(
        icon: Icons.star_rounded,
        label: 'Favourite',
        place: place,
        onTap: onTap,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, size: 20, color: primaryColor),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Place',
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
