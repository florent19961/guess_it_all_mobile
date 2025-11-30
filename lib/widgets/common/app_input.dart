import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppInput extends StatefulWidget {
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final String? error;
  final Widget? prefixIcon;
  final bool showClearButton;
  final VoidCallback? onClear;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final TextEditingController? controller;

  const AppInput({
    this.value,
    this.onChanged,
    this.placeholder,
    this.error,
    this.prefixIcon,
    this.showClearButton = true,
    this.onClear,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.controller,
    super.key,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late TextEditingController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.value);
      _isInternalController = true;
    }
  }

  @override
  void didUpdateWidget(AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInternalController &&
        widget.value != oldWidget.value &&
        widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final borderColor = hasError ? AppColors.error : AppColors.secondaryCyan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          autofocus: widget.autofocus,
          autocorrect: false,
          enableSuggestions: false,
          spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: TextStyle(color: AppColors.gray400),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.showClearButton && _controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                      widget.onClear?.call();
                    },
                    child: const Icon(Icons.close, color: AppColors.gray400),
                  )
                : null,
            filled: true,
            fillColor: AppColors.backgroundCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
          ),
        ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Text(
            widget.error!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
