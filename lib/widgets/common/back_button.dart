import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GameBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GameBackButton({super.key, required this.onPressed});

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
          decoration: BoxDecoration(
            color: AppColors.gray700,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gray500,
              width: 2,
            ),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
