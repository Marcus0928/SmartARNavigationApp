import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/viewmodels/saved_places_viewmodel.dart';

class SavePlacePage extends StatefulWidget {
  const SavePlacePage({
    super.key,
    required this.type,
    required this.label,
    required this.vm,
  });

  final SavedPlaceType type;
  final String label;
  final SavedPlacesViewModel vm;

  @override
  State<SavePlacePage> createState() => _SavePlacePageState();
}

class _SavePlacePageState extends State<SavePlacePage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Set ${widget.label}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: ListenableBuilder(
                  listenable: _controller,
                  builder: (_, __) => _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _controller.clear();
                            widget.vm.clearSearch();
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: widget.vm.searchPlace,
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([widget.vm, _controller]),
        builder: (context, _) {
          final results = widget.vm.searchResults;
          final query = _controller.text.trim();
          final isSearching = widget.vm.isSearching;

          if (isSearching) {
            return const Center(child: CircularProgressIndicator());
          }

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    query.isEmpty
                        ? Icons.search
                        : Icons.location_off_outlined,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    query.isEmpty
                        ? 'Search for a location to set as ${widget.label}'
                        : 'No results found for "$query"',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, index) {
              final place = results[index];
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
                title: Text(
                  place.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
                onTap: () {
                  Navigator.pop(context);
                  widget.vm.selectAndSavePlace(widget.type, place);
                },
              );
            },
          );
        },
      ),
    );
  }
}
