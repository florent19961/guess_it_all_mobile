import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppSlider extends StatelessWidget {
  final double min;
  final double max;
  final double value;
  final ValueChanged<double>? onChanged;
  final String? label;
  final String unit;

  const AppSlider({
    required this.min,
    required this.max,
    required this.value,
    this.onChanged,
    this.label,
    this.unit = '',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Material(
          color: Colors.transparent,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.secondaryCyan,
              inactiveTrackColor: AppColors.gray700,
              thumbColor: AppColors.secondaryCyan,
              overlayColor: AppColors.secondaryCyan.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 8,
            ),
            child: Slider(
              min: min,
              max: max,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
        Center(
          child: Text(
            '${value.toInt()}$unit',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryCyan,
            ),
          ),
        ),
      ],
    );
  }
}
