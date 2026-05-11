import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/viewmodels/plan_drive_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/plan_drive/widgets/option_chip.dart';

class PlanDriveOptionsRow extends StatelessWidget {
  const PlanDriveOptionsRow({super.key, required this.vm});

  final PlanDriveViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          OptionChip(
            label: 'Avoid Tolls',
            active: vm.avoidTolls,
            onTap: vm.toggleAvoidTolls,
          ),
          const SizedBox(width: 8),
          OptionChip(
            label: 'Avoid Highways',
            active: vm.avoidHighways,
            onTap: vm.toggleAvoidHighways,
          ),
        ],
      ),
    );
  }
}
