import 'package:flutter/material.dart';

class FloatingIconButton extends StatelessWidget {
  const FloatingIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: Colors.white,
      child: IconButton(
        icon: Icon(icon, color: Colors.grey.shade700),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
