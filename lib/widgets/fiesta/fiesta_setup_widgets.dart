import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

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
/// sinon « Oui / Non » en lecture seule.
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
