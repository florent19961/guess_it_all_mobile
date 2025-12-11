import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }
enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool disabled;
  final Widget? icon;
  final bool fullWidth;

  const AppButton({
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.disabled = false,
    this.icon,
    this.fullWidth = false,
    super.key,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.disabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.disabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: widget.disabled ? null : () => setState(() => _isPressed = false),
      onTap: widget.disabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          padding: _getPadding(),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(24),
            border: widget.variant == AppButtonVariant.ghost
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: _getFontSize(),
                    color: widget.disabled ? AppColors.gray400 : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 18;
    }
  }

  Color _getBackgroundColor() {
    if (widget.disabled) return AppColors.gray700;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.primaryPink;
      case AppButtonVariant.secondary:
        return AppColors.secondaryCyan;
      case AppButtonVariant.danger:
        return AppColors.error;
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }
}
