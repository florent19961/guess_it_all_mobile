import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChange;
  final int min;
  final int max;
  final String? label;
  final String? error;

  const AppCounter({
    required this.value,
    this.onChange,
    this.min = 0,
    this.max = 100,
    this.label,
    this.error,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircularButton(
              icon: Icons.remove,
              onPressed: value > min ? () => onChange?.call(value - 1) : null,
            ),
            const SizedBox(width: 24),
            Text(
              '$value',
              style: AppTextStyles.title(fontSize: 48),
            ),
            const SizedBox(width: 24),
            _buildCircularButton(
              icon: Icons.add,
              onPressed: value < max ? () => onChange?.call(value + 1) : null,
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onPressed != null ? AppColors.secondaryCyan : AppColors.gray700,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
