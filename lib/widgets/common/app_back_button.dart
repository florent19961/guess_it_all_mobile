import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppBackButton({this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.primaryPink,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
