import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_locations_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/place_options_sheet.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/place_search_sheet.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/quick_actions_section.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/route_preview_card.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/saved_locations_sheet.dart';
import 'package:smart_ar_navigation/views/screens/home/widgets/search_result_item.dart';
import 'package:smart_ar_navigation/views/widgets/search_bar_widget.dart';

class HomeBottomSheet extends StatelessWidget {
  const HomeBottomSheet({
    super.key,
    required this.sheetController,
    required this.mapVM,
    required this.savedVM,
    required this.savedLocationsVM,
    required this.onSearchFocused,
    required this.onStartNavigation,
  });

  final DraggableScrollableController sheetController;
  final MapViewModel mapVM;
  final SavedPlacesViewModel savedVM;
  final SavedLocationsViewModel savedLocationsVM;
  final VoidCallback onSearchFocused;
  final VoidCallback onStartNavigation;

  // ── Utilities ─────────────────────────────────────────────────────────────

  String _formatDistance(double metres) {
    if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
    return '${metres.round()} m';
  }

  // ── Modal sheets ──────────────────────────────────────────────────────────

  void _showPlaceSearch(BuildContext context, SavedPlaceType type, String label) {
    savedVM.clearSearch();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlaceSearchSheet(type: type, label: label, vm: savedVM),
    ).whenComplete(savedVM.clearSearch);
  }

  void _showSavedLocations(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SavedLocationsSheet(vm: savedLocationsVM, mapVM: mapVM),
    );
  }

  // ── Quick-place handlers ──────────────────────────────────────────────────

  void _handleQuickTap(BuildContext context, SavedPlaceType type, String label) {
    final place = savedVM.getPlace(type);
    if (place == null) {
      _showPlaceSearch(context, type, label);
    } else {
      mapVM.setSelectedDestination(place);
    }
  }

  void _handleQuickLongPress(
    BuildContext context,
    SavedPlaceType type,
    String label,
  ) {
    final place = savedVM.getPlace(type);
    if (place == null) return;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlaceOptionsSheet(
        label: label,
        place: place,
        onNavigate: () {
          Navigator.pop(context);
          mapVM.setSelectedDestination(place);
        },
        onEdit: () {
          Navigator.pop(context);
          _showPlaceSearch(context, type, label);
        },
        onRemove: () {
          Navigator.pop(context);
          savedVM.clearPlace(type);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.22,
      minChildSize: 0.12,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.22, 0.40, 0.95],
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DragHandle(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SearchBarWidget(onFocused: onSearchFocused),
                        _buildBody(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (mapVM.searchResults.isNotEmpty) return _buildSearchResults(context);
    if (mapVM.selectedDestination != null) return _buildRoutePreview();
    return _buildIdleContent(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        ...mapVM.searchResults.map((place) {
          final distStr = mapVM.currentLocation != null
              ? _formatDistance(
                  calculateDistance(mapVM.currentLocation!, place.coordinates))
              : null;
          return SearchResultItem(
            place: place,
            distance: distStr,
            isSaved: savedLocationsVM.isSaved(place.placeId),
            onTap: () => mapVM.selectDestination(place),
            onBookmarkTap: () => savedLocationsVM.toggle(place),
          );
        }),
      ],
    );
  }

  Widget _buildRoutePreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        RoutePreviewCard(
          destination: mapVM.selectedDestination!,
          routes: mapVM.previewRoutes,
          selectedIndex: mapVM.selectedRouteIndex,
          isFetching: mapVM.isFetchingRoute,
          onSelectRoute: mapVM.selectRoute,
          onClear: mapVM.clearDestination,
          onStart: onStartNavigation,
        ),
      ],
    );
  }

  Widget _buildIdleContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        QuickActionsSection(
          savedVM: savedVM,
          savedLocationsVM: savedLocationsVM,
          onHomeTap: () => _handleQuickTap(context, SavedPlaceType.home, 'Home'),
          onHomeLongPress: () =>
              _handleQuickLongPress(context, SavedPlaceType.home, 'Home'),
          onWorkTap: () => _handleQuickTap(context, SavedPlaceType.work, 'Work'),
          onWorkLongPress: () =>
              _handleQuickLongPress(context, SavedPlaceType.work, 'Work'),
          onFavouriteTap: () =>
              _handleQuickTap(context, SavedPlaceType.favourite, 'Favourite'),
          onFavouriteLongPress: () =>
              _handleQuickLongPress(context, SavedPlaceType.favourite, 'Favourite'),
          onSavedPlacesTap: () => _showSavedLocations(context),
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
