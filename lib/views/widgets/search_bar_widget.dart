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
      children: [
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
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) =>
              context.read<MapViewModel>().searchDestination(value),
        ),
        if (mapVM.searchResults.isNotEmpty)
          Card(
            margin: EdgeInsets.zero,
            elevation: 4,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
      ],
    );
  }
}
