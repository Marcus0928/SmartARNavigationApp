import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/plan_drive_viewmodel.dart';

class PlanDriveInputCard extends StatelessWidget {
  const PlanDriveInputCard({
    super.key,
    required this.fromController,
    required this.toController,
    required this.fromFocus,
    required this.toFocus,
    required this.vm,
    required this.onSwap,
    required this.onClearTo,
  });

  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocus;
  final FocusNode toFocus;
  final PlanDriveViewModel vm;
  final VoidCallback onSwap;
  final VoidCallback onClearTo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // From row
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(Icons.circle, size: 10, color: primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: fromController,
                  focusNode: fromFocus,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'From',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: vm.searchFrom,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.swap_vert,
                  color: vm.destination != null
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
                onPressed: vm.destination != null ? onSwap : null,
                tooltip: 'Swap origin and destination',
              ),
            ],
          ),
          Divider(height: 1, color: Colors.grey.shade200, indent: 36),
          // To row
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Icon(Icons.location_on, size: 16, color: Colors.red),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: toController,
                  focusNode: toFocus,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Where to?',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: vm.searchTo,
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: toController,
                builder: (_, value, _) => value.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: () {
                          toController.clear();
                          onClearTo();
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
