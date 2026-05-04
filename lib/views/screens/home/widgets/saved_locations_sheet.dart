import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/saved_locations_viewmodel.dart';

class SavedLocationsSheet extends StatelessWidget {
  const SavedLocationsSheet({
    super.key,
    required this.vm,
    required this.mapVM,
  });

  final SavedLocationsViewModel vm;
  final MapViewModel mapVM;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Saved Places',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              if (vm.locations.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_border_rounded,
                          color: Colors.grey.shade400, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Tap the bookmark icon on a search result to save it.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: vm.locations.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final place = vm.locations[i];
                      return ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bookmark_rounded,
                              color: primaryColor, size: 18),
                        ),
                        title: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          place.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.navigation_outlined,
                                  color: primaryColor, size: 20),
                              tooltip: 'Navigate',
                              onPressed: () {
                                Navigator.pop(context);
                                mapVM.setSelectedDestination(place);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Colors.red.shade400, size: 20),
                              tooltip: 'Remove',
                              onPressed: () => vm.remove(place.placeId),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
