import 'package:flutter/material.dart';

import '../../providers/game_provider.dart';
import 'app_confirm_dialog.dart';

/// Dialogues de confirmation **propres au jeu** — c'est-à-dire ceux dont le
/// texte ET l'action sont une décision produit, pas une variation d'écran.
///
/// 🔴 `showBackToVerificationDialog` était recopié à l'identique dans trois
/// écrans (jeu, transition, résultats) : même titre, même phrase, même bouton,
/// même appel à `restorePreValidationState()`. Reformuler la phrase demandait
/// donc trois modifications cohérentes, et rien ne signalait l'oubli d'une.

/// Propose de revenir à l'écran de vérification pour corriger les mots validés.
///
/// Le retour n'est pas un simple changement d'écran : il **restaure** l'état
/// d'avant validation. C'est pour ça que la confirmation est obligatoire.
Future<void> showBackToVerificationDialog(
  BuildContext context,
  GameProvider provider,
) async {
  final confirme = await AppConfirmDialog.show(
    context,
    title: 'Modifier la validation',
    message: 'Voulez-vous revenir à l\'écran de vérification pour corriger '
        'les mots validés ?',
    confirmText: 'Retour',
  );
  if (confirme) provider.restorePreValidationState();
}
