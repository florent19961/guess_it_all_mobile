import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool disabled;

  const AppBackButton({this.onPressed, this.disabled = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: disabled ? AppColors.gray600 : AppColors.primaryPink,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
