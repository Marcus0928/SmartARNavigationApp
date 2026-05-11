import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/profile/widgets/profile_card.dart';
import 'package:smart_ar_navigation/views/screens/profile/widgets/profile_section_label.dart';

class SavedPlacesSection extends StatelessWidget {
  const SavedPlacesSection({
    super.key,
    required this.savedVM,
    required this.onShowPlaceSearch,
  });

  final SavedPlacesViewModel savedVM;
  final void Function(SavedPlaceType, String) onShowPlaceSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionLabel('Saved Places'),
        const SizedBox(height: 10),
        ProfileCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PlaceRow(
                icon: Icons.home_rounded,
                label: 'Home',
                place: savedVM.home,
                onTap: () => onShowPlaceSearch(SavedPlaceType.home, 'Home'),
              ),
              const _Separator(),
              _PlaceRow(
                icon: Icons.work_rounded,
                label: 'Work',
                place: savedVM.work,
                onTap: () => onShowPlaceSearch(SavedPlaceType.work, 'Work'),
              ),
              const _Separator(),
              _AddPlaceRow(
                place: savedVM.favourite,
                onTap: () =>
                    onShowPlaceSearch(SavedPlaceType.favourite, 'Favourite'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

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

  static const _kMuted    = Color(0xFF9E9E9E);
  static const _kSurface2 = Color(0xFFF5F5F5);

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
            const Icon(Icons.edit_outlined, size: 18, color: _kMuted),
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
    if (place != null) {
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

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: Color(0xFFE0E0E0),
      indent: 56,
    );
  }
}
