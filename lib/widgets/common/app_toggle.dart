import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppToggle extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String>? onChange;

  const AppToggle({
    required this.options,
    required this.selected,
    this.onChange,
    super.key,
  }) : assert(options.length == 2, 'AppToggle requires exactly 2 options');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = option == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChange?.call(option),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondaryCyan : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.secondaryCyan : AppColors.gray600,
                  width: 2,
                ),
              ),
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.gray400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
