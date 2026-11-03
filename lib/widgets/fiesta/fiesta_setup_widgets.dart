import 'package:flutter/material.dart';

import '../../models/fiesta/fiesta_rules.dart';
import '../../theme/app_theme.dart';
import '../common/app_back_button.dart';
import '../effects/shooting_stars.dart';
import '../help/help_button.dart';

/// Squelette commun des écrans de choix du mode (Mode de jeu, Fiesta, Auto,
/// Récap) : titre, contenu défilant, bouton bas, et retour — bouton ET geste
/// système (Android) — vers [onBack], pour ne pas quitter l'app par surprise.
class FiestaSetupScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  /// Le « ? » en haut à droite (les écrans Fiesta rouvrent le tuto Fiesta).
  final VoidCallback onHelp;
  final List<Widget> content;
  final Widget bottom;

  const FiestaSetupScaffold({
    required this.title,
    this.subtitle,
    required this.onBack,
    required this.onHelp,
    required this.content,
    required this.bottom,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: ShootingStars(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 48),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.subtitle(fontSize: 40),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle!,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.gray400),
                              ),
                            ],
                            const SizedBox(height: 24),
                            ...content,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    bottom,
                  ],
                ),
              ),
            ),
            AppBackButton(onPressed: onBack),
            HelpButton(onPressed: onHelp),
          ],
        ),
      ),
    );
  }
}

/// Carte sélectionnable (maquette `.pick`).
class FiestaPickCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const FiestaPickCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.secondaryCyan : AppColors.gray600,
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondaryCyan.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  icon,
                  style: const TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 22,
                    color: AppColors.secondaryCyan,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.label),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte à titre en capitales (maquette `.card`), [trailing] à droite du titre.
class FiestaCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const FiestaCard({
    required this.title,
    this.trailing,
    this.children = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: AppColors.gray400,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (children.isNotEmpty) const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// Ligne libellé + détail, avec un interrupteur si [onChanged] est donné,
/// sinon « Oui / Non » en lecture seule (Récap).
class FiestaLine extends StatelessWidget {
  final String label;
  final String? detail;
  final bool? value;
  final ValueChanged<bool>? onChanged;

  const FiestaLine({
    required this.label,
    this.detail,
    this.value,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                if (detail != null)
                  Text(
                    detail!,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
              ],
            ),
          ),
          if (v != null && onChanged != null)
            Switch(
              value: v,
              onChanged: onChanged,
              activeTrackColor: AppColors.secondaryCyan,
            )
          else if (v != null)
            Text(
              v ? 'Oui' : 'Non',
              style: AppTextStyles.label.copyWith(
                color: v ? AppColors.secondaryCyan : AppColors.gray500,
              ),
            ),
        ],
      ),
    );
  }
}

/// La règle commune Fiesta (maquette `commonCard`). Le temps reporté de fin
/// de manche n'est pas un réglage : il est toujours conservé.
class FiestaCommonRulesCard extends StatelessWidget {
  final bool oneAnswer;

  /// Nul = lecture seule (Récap).
  final void Function({bool? oneAnswer})? onChanged;

  const FiestaCommonRulesCard({
    required this.oneAnswer,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final edit = onChanged;
    return FiestaCard(
      title: 'Règles communes Fiesta',
      children: [
        FiestaLine(
          label: 'Une seule réponse',
          detail: 'Une proposition par mot. Mauvaise réponse → il faut passer '
              '(pénalité de passe). Simple annonce, l\'app ne vérifie pas.',
          value: oneAnswer,
          onChanged: edit == null ? null : (v) => edit(oneAnswer: v),
        ),
      ],
    );
  }
}

/// Texte d'explication gris (maquette `.hint`).
class FiestaHint extends StatelessWidget {
  final String text;
  const FiestaHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.bodySmall
            .copyWith(fontSize: 12, color: AppColors.gray400),
      );
}

/// Résumé d'une ligne du rattrapage, pour le Récap (Auto et Personnalisé).
String catchUpSummary(CatchUpRules c) =>
    '+${c.b1} s / +${c.b2} s × écart (max +${c.cap} s) · '
    'leader −${c.mal} s × écart (max −${c.malCap} s)';
