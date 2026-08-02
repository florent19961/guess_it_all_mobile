import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_button.dart';

/// Dialogue de confirmation « Annuler / Confirmer ».
///
/// 🔴 Ce composant existe parce que le MÊME dialogue était recopié à l'octet
/// près dans 6 endroits, sur 4 écrans : même `AlertDialog`, même
/// `RoundedRectangleBorder` de rayon 24, mêmes styles de titre et de corps,
/// mêmes deux `AppButton` en `spaceEvenly`. Seuls le texte et la couleur de
/// bordure changeaient. Toute retouche visuelle demandait donc 6 modifications
/// cohérentes — et il suffisait d'en oublier une pour que l'app diverge d'elle
/// même sans que rien ne le signale.
///
/// Rend `true` si l'utilisateur confirme, `false` s'il annule, et `false` aussi
/// s'il ferme en tapant à côté : l'absence de choix n'est jamais un accord.
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  /// Couleur de bordure — c'est le seul axe de variation entre les usages
  /// (neutre, avertissement, information).
  final Color accentColor;

  const AppConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = 'Annuler',
    this.accentColor = AppColors.gray500,
    super.key,
  });

  /// Affiche le dialogue et rend le choix de l'utilisateur.
  ///
  /// ⚠️ Le `?? false` n'est pas une précaution de style : `showDialog` rend
  /// `null` quand l'utilisateur ferme en tapant en dehors. Traiter ce cas comme
  /// une confirmation abandonnerait une partie sur un tap malencontreux.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    String cancelText = 'Annuler',
    Color accentColor = AppColors.gray500,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: barrierDismissible,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        accentColor: accentColor,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundMain,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accentColor, width: 2),
      ),
      title: Text(
        title,
        style: AppTextStyles.subtitle(fontSize: 24),
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        AppButton(
          text: cancelText,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          text: confirmText,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
