import 'fiesta_ensemble.dart';
import 'fiesta_rules.dart';
import 'modifier_catalog.dart';

/// Ce que la liste dit d'un ensemble : ligne courte, explication, pastilles.
///
/// Fournis : écrits à la main ([kProvidedSummaries]). Perso : générés depuis
/// les règles, jamais de texte libre, rien de stocké. Seul ce qui joue compte,
/// comme pour `settingsKey` : `balance` remplace `trailingCount`, pas de pool
/// sans tirage, rien de verrouillé.
class EnsembleSummary {
  final String short;
  final String long;
  final List<EnsembleChip> chips;

  const EnsembleSummary({
    required this.short,
    required this.long,
    required this.chips,
  });
}

sealed class EnsembleChip {
  const EnsembleChip();
}

/// Un modificateur du catalogue ; [count] : ses cartouches, s'il en est une.
final class ModifierChip extends EnsembleChip {
  final String id;
  final int? count;
  const ModifierChip(this.id, {this.count});
}

/// Tout le reste (tirages, cartouches au hasard) : une pastille neutre.
final class InfoChip extends EnsembleChip {
  final String label;
  const InfoChip(this.label);
}

// ---------------------------------------------------------------------------
// Libellés partagés avec la page « Voir ».
// ---------------------------------------------------------------------------

const String kBalanceLabel = 'Équilibrer la partie';
const String kChallengesLabel = 'Défis surprises';

String _plural(int n, String word) => '$n $word${n > 1 ? 's' : ''}';

String _trailingLabel(int n) =>
    'Aux équipes menées : ${_plural(n, 'cartouche')}';

String _allLabel(int n) =>
    'À tous, à chaque manche : ${_plural(n, 'cartouche')}';

/// Cartouches d'un modificateur, données à chaque équipe.
String perTeamLabel(int charges) => '×$charges pour chaque équipe';

/// Les cartouches au hasard et les défis : une phrase par réglage qui joue.
List<String> randomCartridgeLines(FiestaRules rules) => [
      if (rules.balance)
        '$kBalanceLabel : plus une équipe est distancée, plus elle reçoit de '
            'cartouches'
      else if (rules.trailingCount > 0)
        '${_trailingLabel(rules.trailingCount)} après les manches 1 et 2',
      if (rules.allCount > 0) _allLabel(rules.allCount),
      if (rules.challenges)
        '$kChallengesLabel : 1 ou 2 fois dans la partie, une cartouche à gagner',
    ];

// ---------------------------------------------------------------------------
// Ce qui joue.
// ---------------------------------------------------------------------------

/// Un tirage a lieu à chaque manche : un nombre, et de quoi tirer.
bool rulesDraw(FiestaRules rules) =>
    rules.drawCount > 0 && kModifierCatalog.any((d) => rules.drawsFrom(d.id));

/// Une cartouche, sous n'importe quelle forme, peut arriver en partie.
bool rulesHaveCartridges(FiestaRules rules) =>
    rules.balance ||
    rules.challenges ||
    rules.trailingCount > 0 ||
    rules.allCount > 0 ||
    kModifierCatalog.any((d) => rules.chargesOf(d.id) > 0);

// ---------------------------------------------------------------------------
// Texte.
// ---------------------------------------------------------------------------

EnsembleSummary ensembleSummary(FiestaEnsemble ensemble) =>
    kProvidedSummaries[ensemble.id] ?? rulesSummary(ensemble.rules);

EnsembleSummary rulesSummary(FiestaRules rules) {
  final always = kModifierCatalog.where((d) => rules.isAlways(d.id)).toList();
  final draws = rulesDraw(rules);
  final cartridges =
      kModifierCatalog.where((d) => rules.chargesOf(d.id) > 0).toList();
  final charges = cartridges.fold<int>(0, (n, d) => n + rules.chargesOf(d.id));
  final drawn = rules.drawCount > 1 ? 'tirées' : 'tirée';

  final longParts = [
    if (always.isNotEmpty) 'Toujours : ${always.map((d) => d.name).join(', ')}',
    if (draws) '${_plural(rules.drawCount, 'règle')} $drawn à chaque manche',
    for (final d in cartridges)
      '${d.name} : ${perTeamLabel(rules.chargesOf(d.id))}',
    ...randomCartridgeLines(rules),
  ];

  return EnsembleSummary(
    short: _shortLine([
      if (always.isNotEmpty)
        '${_plural(always.length, 'règle')} '
            '${always.length > 1 ? 'fixes' : 'fixe'}',
      if (draws) '${rules.drawCount} $drawn par manche',
      if (charges > 0) _plural(charges, 'cartouche'),
      if (rules.balance)
        'Équilibrage'
      else if (rules.trailingCount > 0)
        '${_plural(rules.trailingCount, 'cartouche')} aux menées',
      if (rules.allCount > 0)
        '${_plural(rules.allCount, 'cartouche')} par manche',
      if (rules.challenges) kChallengesLabel,
    ]),
    long: longParts.isEmpty
        ? 'Cet ensemble n\'a aucune règle active.'
        : '${longParts.join('. ')}.',
    chips: [
      for (final d in always) ModifierChip(d.id),
      if (draws) InfoChip('${_plural(rules.drawCount, 'tirage')} par manche'),
      for (final d in cartridges)
        ModifierChip(d.id, count: rules.chargesOf(d.id)),
      if (rules.balance)
        const InfoChip(kBalanceLabel)
      else if (rules.trailingCount > 0)
        InfoChip(_trailingLabel(rules.trailingCount)),
      if (rules.allCount > 0) InfoChip(_allLabel(rules.allCount)),
      if (rules.challenges) const InfoChip(kChallengesLabel),
    ],
  );
}

/// Longueur qui tient sur 2 lignes à 360 px (mesurée par
/// `fiesta_ensembles_list_test`).
const int _shortLineBudget = 57;

/// Les [parts] tant qu'elles tiennent ; le dépliage dit le reste.
String _shortLine(List<String> parts) {
  const more = 'et plus';
  if (parts.isEmpty) return 'Aucune règle active';
  var line = parts.first;
  for (var i = 1; i < parts.length; i++) {
    final next = '$line · ${parts[i]}';
    final isLast = i == parts.length - 1;
    if (next.length + (isLast ? 0 : ' · $more'.length) > _shortLineBudget) {
      return '$line · $more';
    }
    line = next;
  }
  return line;
}

// ---------------------------------------------------------------------------
// Ensembles fournis, écrits à la main.
// ---------------------------------------------------------------------------

/// Par id d'ensemble fourni. Les pastilles disent les mêmes règles que
/// `kProvidedEnsembles`, dans l'ordre choisi ici (test).
final Map<String, EnsembleSummary> kProvidedSummaries = {
  kClassicEnsembleId: EnsembleSummary(
    short: '5 cartouches à chaque manche',
    long: 'Chaque équipe reçoit 5 cartouches au hasard au début de chaque '
        'manche. Plus une équipe est distancée, plus elle en reçoit en plus.',
    chips: [InfoChip(_allLabel(5)), const InfoChip(kBalanceLabel)],
  ),
  '${kProvidedIdPrefix}last': EnsembleSummary(
    short: '5 cartouches aux équipes menées',
    long: 'Après les manches 1 et 2, chaque équipe menée reçoit 5 cartouches '
        'au hasard.',
    chips: [InfoChip(_trailingLabel(5))],
  ),
  '${kProvidedIdPrefix}pro': const EnsembleSummary(
    short: '3 règles dures, toute la partie',
    long: 'Trois contraintes actives du début à la fin de la partie.',
    chips: [
      ModifierChip('no_pass'),
      ModifierChip('reversed'),
      ModifierChip('one_answer'),
    ],
  ),
  '${kProvidedIdPrefix}straight': const EnsembleSummary(
    short: 'Une seule réponse par mot',
    long: 'Une seule réponse par mot, toute la partie.',
    chips: [ModifierChip('one_answer')],
  ),
  '${kProvidedIdPrefix}pictionary': const EnsembleSummary(
    short: 'On dessine en manche 3',
    long: 'En manche 3, on dessine au lieu de mimer.',
    chips: [ModifierChip('draw')],
  ),
  '${kProvidedIdPrefix}bilingual': const EnsembleSummary(
    short: 'Une autre langue, manches 1 et 2',
    long: 'En manches 1 et 2, on fait deviner en parlant une autre langue.',
    chips: [ModifierChip('other_language')],
  ),
  '${kProvidedIdPrefix}explosive': EnsembleSummary(
    short: '10 cartouches à chaque manche',
    long: 'Chaque équipe reçoit 10 cartouches au hasard au début de chaque '
        'manche.',
    chips: [InfoChip(_allLabel(10))],
  ),
  '${kProvidedIdPrefix}expert': const EnsembleSummary(
    short: 'Manche 3 sous un drap, en bruitages',
    long: 'En manche 3, on mime sous un drap, avec des bruitages seulement.',
    chips: [ModifierChip('sounds_only'), ModifierChip('mime_under_sheet')],
  ),
};
