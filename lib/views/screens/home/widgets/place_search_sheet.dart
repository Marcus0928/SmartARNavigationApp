import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';

class PlaceSearchSheet extends StatefulWidget {
  const PlaceSearchSheet({
    super.key,
    required this.type,
    required this.label,
    required this.vm,
  });

  final SavedPlaceType type;
  final String label;
  final SavedPlacesViewModel vm;

  @override
  State<PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<PlaceSearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Set ${widget.label} location',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search for a place...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: widget.vm.searchPlace,
                ),
              ),
              const SizedBox(height: 4),
              ...widget.vm.searchResults.map(
                (place) => ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey,
                  ),
                  title: Text(
                    place.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    place.address,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.vm.selectAndSavePlace(widget.type, place);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
