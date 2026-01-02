import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppModal extends StatelessWidget {
  final String? title;
  final Widget child;
  final VoidCallback onClose;

  const AppModal({
    this.title,
    required this.child,
    required this.onClose,
    super.key,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AppModal(
        title: title,
        onClose: () => Navigator.of(context).pop(),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundMain,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.secondaryCyan, width: 2),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close, color: AppColors.gray400, size: 24),
                ),
              ),
              if (title != null) ...[
                Text(
                  title!,
                  style: AppTextStyles.subtitle(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}
