import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapVM = context.watch<MapViewModel>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Results expand upward above the search bar
        if (mapVM.searchResults.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: Card(
              margin: const EdgeInsets.only(bottom: 4),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: mapVM.searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final place = mapVM.searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(place.name),
                    subtitle: Text(
                      place.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _controller.text = place.name;
                      context.read<MapViewModel>().selectDestination(place);
                    },
                  );
                },
              ),
            ),
          ),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      context.read<MapViewModel>().clearDestination();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) =>
              context.read<MapViewModel>().searchDestination(value),
        ),
      ],
    );
  }
}
