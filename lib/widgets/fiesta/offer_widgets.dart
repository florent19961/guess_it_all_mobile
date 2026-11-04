import 'package:flutter/material.dart';

import '../../models/fiesta/modifier_catalog.dart';
import '../../models/fiesta/modifier_instance.dart';
import '../../models/fiesta/offers.dart';
import '../../models/team.dart';
import '../../theme/app_theme.dart';
import '../common/app_button.dart';
import 'fiesta_setup_widgets.dart';
import 'modifier_badge.dart';

/// Kit visuel de 2-10 (maquettes `r2` et `pick3`) : données en entrée,
/// callbacks en sortie, aucune lecture de Provider.

String _name(List<Team> teams, String id) {
  for (final t in teams) {
    if (t.id == id) return t.name;
  }
  return id;
}

/// Force RÉELLE d'une offre : elle peut être d'un cran sous celle de
/// l'écart, quand la force de l'écart n'avait aucune carte utile.
String _strength(ModifierInstance offer) =>
    strengthLabel(kOfferStrength[offer.catalogId] ?? OfferStrength.light);

Color _color(List<Team> teams, String id) {
  final index = teams.indexWhere((t) => t.id == id);
  return AppColors.getTeamColor(index < 0 ? 0 : index);
}

/// « Choix 1 parmi 3 » sur la transition. [nextTeamId] = la prochaine équipe
/// de la file ; `null` = file vide (tous les choix sont faits).
class PickThreeCard extends StatelessWidget {
  final List<Team> teams;
  final String? nextTeamId;
  final VoidCallback onPassPhone;

  const PickThreeCard({
    required this.teams,
    required this.nextTeamId,
    required this.onPassPhone,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final next = nextTeamId;
    if (next == null) {
      return const FiestaCard(
        title: 'Choix 1 parmi 3',
        children: [FiestaHint('Tous les choix sont faits.')],
      );
    }
    final name = _name(teams, next);
    // Pas d'écart chiffré : les scores restent cachés jusqu'aux résultats.
    return FiestaCard(
      title: 'Choix 1 parmi 3',
      children: [
        FiestaHint('Au choix : $name'),
        const SizedBox(height: 10),
        AppButton(
          text: 'Passe le téléphone : $name',
          variant: AppButtonVariant.secondary,
          fullWidth: true,
          onPressed: onPassPhone,
        ),
      ],
    );
  }
}

/// Écran « Passer le téléphone » : sépare deux équipes de la file sans rien
/// révéler des offres de la suivante.
class PassPhonePanel extends StatelessWidget {
  final String teamName;
  final Color teamColor;
  final VoidCallback onReady;

  const PassPhonePanel({
    required this.teamName,
    required this.teamColor,
    required this.onReady,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundMain,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Passe le téléphone :',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.gray400),
                ),
                const SizedBox(height: 8),
                Text(
                  teamName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle(fontSize: 40)
                      .copyWith(color: teamColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les autres équipes ne regardent pas l\'écran.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.gray400),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'C\'est nous : voir les cartes',
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: onReady,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Corps de l'écran de choix (maquette `pick3`) : équipe, force, ordre de la
/// file, une ou plusieurs rangées de 3 cartes (une carte par rangée, sur le
/// même écran), « Valider ». La sélection est tenue par l'appelant
/// ([selected] : rangée → index, [onSelect]) ; [isUsable] grise une carte que
/// les autres sélections rendent sans effet ; [ready] = chaque rangée a sa
/// carte ou n'en a plus d'utile.
class OfferChoiceBody extends StatelessWidget {
  /// La manche N qui vient de finir.
  final int round;
  final List<Team> teams;
  final Standings standings;
  final String chooserId;
  final List<List<ModifierInstance>> rows;
  final Map<int, int> selected;
  final bool Function(int row, int index) isUsable;
  final bool ready;
  final void Function(int row, int index) onSelect;
  final VoidCallback onConfirm;

  const OfferChoiceBody({
    required this.round,
    required this.teams,
    required this.standings,
    required this.chooserId,
    required this.rows,
    required this.selected,
    required this.isUsable,
    required this.ready,
    required this.onSelect,
    required this.onConfirm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final order = standings.choosingOrder;
    final leaders = standings.leaderIds.map((id) => _name(teams, id)).toList();
    final hint = AppTextStyles.bodySmall
        .copyWith(fontSize: 12.5, color: AppColors.gray400);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Entre la manche $round et la manche ${round + 1}',
                        textAlign: TextAlign.center, style: hint),
                    const SizedBox(height: 4),
                    Text(
                      _name(teams, chooserId),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subtitle(fontSize: 34)
                          .copyWith(color: _color(teams, chooserId)),
                    ),
                    // Force de l'offre, jamais l'écart chiffré (scores
                    // cachés jusqu'aux résultats).
                    Text(
                      rows.isEmpty
                          ? 'En retard'
                          : 'En retard · offre ${_strength(rows.first.first)}',
                      textAlign: TextAlign.center,
                      style: hint,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Text('Ordre :', style: hint),
                        for (final (i, id) in order.indexed) ...[
                          if (i > 0) Text('→', style: hint),
                          _QueueChip(
                              name: _name(teams, id), now: id == chooserId),
                        ],
                        Text(
                          '· ${leaders.join(', ')} (en tête) '
                          '${leaders.length > 1 ? 'ne choisissent' : 'ne choisit'}'
                          ' pas',
                          style: hint,
                        ),
                      ],
                    ),
                    if (rows.length > 1) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Prends une carte par rangée ; les autres sont '
                        'perdues.',
                        textAlign: TextAlign.center,
                        style: hint,
                      ),
                    ],
                    for (final (r, row) in rows.indexed) ...[
                      const SizedBox(height: 16),
                      if (rows.length > 1) ...[
                        Text('CARTE ${r + 1}',
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.gray400, fontSize: 12)),
                        const SizedBox(height: 8),
                      ],
                      for (final (i, offer) in row.indexed)
                        _OfferCard(
                          offer: offer,
                          who: offer.teamId == chooserId
                              ? 'Pour vous'
                              : 'Contre ${_name(teams, offer.teamId!)}',
                          selected: selected[r] == i,
                          enabled: selected[r] == i || isUsable(r, i),
                          onTap: () => onSelect(r, i),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: !ready
                  ? (rows.length > 1
                      ? 'Choisis une carte par rangée'
                      : 'Choisis une carte')
                  : (selected.length > 1
                      ? 'Valider ces choix'
                      : 'Valider ce choix'),
              size: AppButtonSize.large,
              fullWidth: true,
              disabled: !ready,
              onPressed: ready ? onConfirm : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueChip extends StatelessWidget {
  final String name;
  final bool now;

  const _QueueChip({required this.name, required this.now});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.backgroundMain,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: now ? AppColors.secondaryCyan : AppColors.gray600),
        ),
        child: Text(
          name,
          style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12.5,
              color: now ? AppColors.secondaryCyan : AppColors.gray400),
        ),
      );
}

/// Une offre sélectionnable (maquette `.pick`), avec sa cible en pastille.
class _OfferCard extends StatelessWidget {
  final ModifierInstance offer;
  final String who;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OfferCard({
    required this.offer,
    required this.who,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final def = modifierById(offer.catalogId);
    final color = modifierColor(offer.nature);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.35,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundMain,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      selected ? AppColors.secondaryCyan : Colors.transparent,
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
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      modifierIcon(offer.catalogId),
                      style: TextStyle(
                          fontFamily: 'Bangers', fontSize: 22, color: color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(def?.name ?? offer.catalogId,
                            style: AppTextStyles.label),
                        if (def != null) FiestaHint(def.description),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: AppColors.gray600),
                          ),
                          child: Text(
                            offer.charges > 0
                                ? '$who · +${offer.charges}'
                                : who,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                color: AppColors.gray400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// « Coup de pouce de l'app » (Auto) en une ligne : ce que l'app donne à
/// chaque équipe menée et impose à l'équipe en tête, avec la force appliquée.
/// Rien si [gifts] est vide.
class AppBoostLine extends StatelessWidget {
  final List<Team> teams;
  final List<ModifierInstance> gifts;

  const AppBoostLine({
    required this.teams,
    required this.gifts,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (gifts.isEmpty) return const SizedBox.shrink();
    return FiestaInfoLine(
      label: 'Coup de pouce de l\'app',
      spans: [
        for (final (i, gift) in gifts.indexed) ...[
          if (i > 0) const TextSpan(text: ' · '),
          TextSpan(
            text: '${_name(teams, gift.teamId!)} '
                '${gift.nature == ModifierNature.bonus ? 'reçoit' : 'subit'} ',
            style: TextStyle(color: _color(teams, gift.teamId!)),
          ),
          modifierBadgeSpan(ModifierBadge.of(gift)),
          TextSpan(text: ' (${_strength(gift)})'),
        ],
      ],
    );
  }
}
