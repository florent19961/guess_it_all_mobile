import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/ensemble_summary.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensembles_screen.dart';
import 'package:guess_it_all_mobile/services/fiesta_ensemble_service.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';
import 'package:guess_it_all_mobile/theme/app_theme.dart';
import 'package:guess_it_all_mobile/widgets/fiesta/modifier_badge.dart';

import '../helpers/test_prefs.dart';
import 'fiesta_v4_screens_test.dart' show loadFonts, settle;

const _longName = 'Soirée interminable chez Maximilien et ses cousins';
const _sizes = [Size(360, 640), Size(390, 844)];

/// Un ensemble perso qui joue tout, au maximum.
final _everything = FiestaRules(
  ensembleName: _longName,
  modifiers: {
    'no_pass': const ModifierSetting(always: true),
    'reversed': const ModifierSetting(always: true),
    'one_answer': const ModifierSetting(always: true),
    'other_language': const ModifierSetting(draw: true),
    'double_points': const ModifierSetting(charges: 5),
    'plus_10s': const ModifierSetting(charges: 5),
    'minus_10s': const ModifierSetting(charges: 5),
    'block_guesser': const ModifierSetting(charges: 5),
    'block_giver': const ModifierSetting(charges: 5),
  },
  drawCount: 5,
  allCount: 5,
  balance: true,
  challenges: true,
);

Future<void> pumpList(
  WidgetTester tester,
  Size size, {
  List<FiestaRules> mine = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await givenPrefs({
    if (mine.isNotEmpty)
      FiestaEnsembleService.storageKey: jsonEncode(wrapWithSchema({
        'ensembles': [
          for (final (i, rules) in mine.indexed)
            FiestaEnsemble(id: 'mine$i', rules: rules).toJson(),
        ],
      })),
  });
  await tester.pumpWidget(MaterialApp(
    home: FiestaEnsemblesScreen(onBack: () {}, onNext: (_) {}),
  ));
  await settle(tester);
}

List<FiestaRules> tenMine() => [
      for (var i = 0; i < FiestaEnsembleService.maxEnsembles; i++)
        FiestaRules(ensembleName: 'Mien $i', allCount: 1),
    ];

/// La ligne entière (cadre et dépliage) de l'ensemble [name].
Finder rowOf(String name) => find
    .ancestor(
      of: find.text(name),
      matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_EnsembleCard'),
    )
    .first;

Future<void> select(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text(name));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(name));
  await tester.pump();
  // 1ʳᵉ image : le défilement démarre ; 2ᵉ : il finit.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// La ligne doit tenir dans la liste, entre la bande des boutons du haut et la
/// barre « Suivant ». Plus haute (règles extrêmes) : son haut d'abord.
void expectFullyVisible(WidgetTester tester, String name) {
  final row = tester.getRect(rowOf(name));
  final bar = tester.getTopLeft(find.text('Suivant')).dy;
  expect(row.top, greaterThanOrEqualTo(72), reason: name);
  if (row.height <= bar - 72) {
    expect(row.bottom, lessThanOrEqualTo(bar), reason: name);
  }
}

Finder iconIn(String name, IconData icon) =>
    find.descendant(of: rowOf(name), matching: find.byIcon(icon));

void main() {
  setUpAll(loadFonts);

  group('Lignes sans débordement', () {
    for (final size in _sizes) {
      final label = '${size.width.toInt()} × ${size.height.toInt()}';

      testWidgets(
          '$label, sans perso : chaque fourni se déplie et reste visible',
          (tester) async {
        await pumpList(tester, size);
        for (final ensemble in kProvidedEnsembles) {
          await select(tester, ensemble.name);
          expectFullyVisible(tester, ensemble.name);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('$label, perso au nom long et aux règles maximales',
          (tester) async {
        await pumpList(tester, size, mine: [_everything]);
        await select(tester, _longName);
        expectFullyVisible(tester, _longName);
        final name = tester.widget<Text>(find.text(_longName));
        expect(name.maxLines, 2);
        final short = find.descendant(
          of: rowOf(_longName),
          matching: find.text(
              ensembleSummary(FiestaEnsemble(id: 'x', rules: _everything))
                  .short),
        );
        expect(short, findsOneWidget);
        // Plus haute que l'écran : ses actions restent atteignables en défilant.
        await tester.ensureVisible(find.byTooltip('Supprimer'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byTooltip('Modifier'), warnIfMissed: true);
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('$label, 10 perso : la dernière ligne reste visible',
          (tester) async {
        await pumpList(tester, size, mine: tenMine());
        await select(tester, 'Mien 9');
        expectFullyVisible(tester, 'Mien 9');
        expect(
            find.descendant(
                of: rowOf('Mien 9'), matching: find.byTooltip('Supprimer')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        '« Les derniers seront les premiers » se lit en entier à 360 px',
        (tester) async {
      await pumpList(tester, const Size(360, 640));
      const name = 'Les derniers seront les premiers';
      await tester.ensureVisible(find.text(name));
      await tester.pump(const Duration(milliseconds: 300));
      final paragraph = tester.renderObject<RenderParagraph>(find.text(name));
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets(
        'le texte court tient sur 2 lignes à 360 px, sans ellipse, quelles que '
        'soient les règles', (tester) async {
      final worst = <FiestaRules>[];
      for (final always in [false, true]) {
        for (final draw in [false, true]) {
          for (final charges in [false, true]) {
            for (final hazard in [0, 1, 2]) {
              for (final all in [false, true]) {
                for (final challenges in [false, true]) {
                  worst.add(FiestaRules(
                    ensembleName: 'Combo ${worst.length}',
                    modifiers: {
                      if (always)
                        for (final id in ['no_pass', 'reversed'])
                          id: const ModifierSetting(always: true),
                      if (draw) 'one_answer': const ModifierSetting(draw: true),
                      if (charges)
                        for (final id in ['double_points', 'plus_10s'])
                          id: const ModifierSetting(charges: 5),
                    },
                    drawCount: draw ? 5 : 0,
                    balance: hazard == 1,
                    trailingCount: hazard == 2 ? 5 : 0,
                    allCount: all ? 5 : 0,
                    challenges: challenges,
                  ));
                }
              }
            }
          }
        }
      }
      await pumpList(tester, const Size(360, 640), mine: [_everything]);
      await tester.ensureVisible(find.text(_longName));
      await tester.pump(const Duration(milliseconds: 300));
      final sample = find.descendant(
        of: rowOf(_longName),
        matching: find.text(rulesSummary(_everything).short),
      );
      final style = tester.widget<Text>(sample).style!;
      final width = tester
          .getSize(
              find.ancestor(of: sample, matching: find.byType(Column)).first)
          .width;
      for (final rules in worst) {
        final short = rulesSummary(rules).short;
        final painter = TextPainter(
          text: TextSpan(text: short, style: style),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width);
        expect(painter.computeLineMetrics().length, lessThanOrEqualTo(2),
            reason: short);
      }
    });
  });

  group('Sélection et dépliage', () {
    testWidgets('seule la ligne sélectionnée se déplie et porte des actions',
        (tester) async {
      await pumpList(tester, const Size(390, 844));
      final classic = kProvidedSummaries[kClassicEnsembleId]!;
      expect(find.text(classic.long), findsOneWidget);
      expect(find.byTooltip('Voir'), findsOneWidget);
      expect(find.byTooltip('Dupliquer'), findsOneWidget);

      await select(tester, 'Pro Player');
      expect(find.text(classic.long), findsNothing);
      expect(find.text(classic.short), findsOneWidget, reason: 'ligne courte');
      expect(find.text(kProvidedSummaries['${kProvidedIdPrefix}pro']!.long),
          findsOneWidget);
      expect(find.byTooltip('Voir'), findsOneWidget);
      expect(
          find.descendant(
              of: rowOf('Pro Player'), matching: find.byTooltip('Voir')),
          findsOneWidget);
    });

    testWidgets('toucher la ligne déjà sélectionnée ne la replie pas',
        (tester) async {
      await pumpList(tester, const Size(390, 844));
      final long = kProvidedSummaries[kClassicEnsembleId]!.long;
      await tester.tap(find.text('Fiesta classique'));
      await tester.pump();
      expect(find.text(long), findsOneWidget);
      await tester.tap(find.text(long));
      await tester.pump();
      expect(find.text(long), findsOneWidget);
    });

    testWidgets('fourni : Voir et Dupliquer seulement, sans badge',
        (tester) async {
      await pumpList(tester, const Size(360, 640));
      final row = rowOf('Fiesta classique');
      expect(find.descendant(of: row, matching: find.byType(IconButton)),
          findsNWidgets(2));
      for (final label in ['Voir', 'Dupliquer']) {
        expect(find.descendant(of: row, matching: find.byTooltip(label)),
            findsOneWidget);
      }
      expect(find.text('Perso'), findsNothing);
    });

    testWidgets(
        'perso : 4 actions de 44 px sur une ligne, alignées à droite, libellées',
        (tester) async {
      await pumpList(tester, const Size(360, 640),
          mine: [FiestaRules(ensembleName: _longName, allCount: 1)]);
      await select(tester, _longName);
      final row = rowOf(_longName);
      final rects = [
        for (final label in ['Voir', 'Modifier', 'Dupliquer', 'Supprimer'])
          tester.getRect(
              find.descendant(of: row, matching: find.byTooltip(label))),
      ];
      for (final rect in rects) {
        expect(rect.size, const Size(44, 44));
        expect(rect.top, rects.first.top, reason: 'une seule ligne');
      }
      expect(rects.last.right, greaterThan(tester.getRect(row).right - 16));
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].left, rects[i - 1].right, reason: 'côte à côte');
      }
      expect(find.descendant(of: row, matching: find.text('Perso')),
          findsOneWidget);
    });

    testWidgets('sélectionné : tuile pleine, icône sombre, rond plein et coche',
        (tester) async {
      await pumpList(tester, const Size(390, 844));
      Color iconColor(String name, IconData icon) =>
          tester.widget<Icon>(iconIn(name, icon)).color!;
      BoxDecoration tileOf(String name, IconData icon) => tester
          .widget<Container>(find
              .ancestor(
                  of: iconIn(name, icon), matching: find.byType(Container))
              .first)
          .decoration! as BoxDecoration;

      expect(iconColor('Fiesta classique', Icons.casino_outlined),
          AppColors.backgroundMain);
      expect(tileOf('Fiesta classique', Icons.casino_outlined).color,
          AppColors.secondaryCyan);
      expect(iconIn('Fiesta classique', Icons.check), findsOneWidget);

      expect(iconColor('Pro Player', Icons.emoji_events_outlined),
          AppColors.secondaryCyan);
      expect(tileOf('Pro Player', Icons.emoji_events_outlined).color,
          AppColors.secondaryCyan.withValues(alpha: 0.14));
      expect(iconIn('Pro Player', Icons.check), findsNothing);
    });
  });

  testWidgets(
      'à l\'ouverture, l\'ensemble en attente en bas de liste est visible',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final mine = tenMine();
    await givenPrefs({
      FiestaEnsembleService.storageKey: jsonEncode(wrapWithSchema({
        'ensembles': [
          for (final (i, rules) in mine.indexed)
            FiestaEnsemble(id: 'mine$i', rules: rules).toJson(),
        ],
      })),
    });
    await tester.pumpWidget(MaterialApp(
      home: FiestaEnsemblesScreen(
          onBack: () {}, onNext: (_) {}, selected: mine.last),
    ));
    await settle(tester);
    expectFullyVisible(tester, 'Mien 9');
  });

  testWidgets(
      'la liste s\'arrête sous les boutons du haut, et le titre défile avec elle',
      (tester) async {
    await pumpList(tester, const Size(360, 640), mine: tenMine());
    final title = find.text('Ensembles Fiesta');
    expect(tester.getTopLeft(title).dy, 72, reason: 'ouverture inchangée');

    await select(tester, 'Mien 9');
    expect(title.hitTestable(), findsNothing, reason: 'le titre a défilé');
    final top = tester.getTopLeft(find.byType(SingleChildScrollView)).dy;
    expect(top, 72);
    // Un point de la bande : aucune ligne n'y répond.
    final band = tester.hitTestOnBinding(const Offset(180, 40));
    final hit = band.path.map((e) => e.target).toSet();
    final rows = find
        .byWidgetPredicate((w) => w.runtimeType.toString() == '_EnsembleCard');
    for (final row in rows.evaluate()) {
      expect(hit.contains(row.findRenderObject()), isFalse);
    }
  });

  group('Pastilles', () {
    testWidgets('modificateur : ModifierBadge et sa fiche ; le reste, neutre',
        (tester) async {
      await pumpList(tester, const Size(390, 844), mine: [
        FiestaRules(
          ensembleName: 'Soirée du samedi',
          modifiers: {
            'one_answer': const ModifierSetting(always: true),
            'reversed': const ModifierSetting(draw: true),
            'double_points': const ModifierSetting(charges: 1),
          },
          drawCount: 2,
        ),
      ]);
      await select(tester, 'Soirée du samedi');
      final row = rowOf('Soirée du samedi');
      expect(find.descendant(of: row, matching: find.byType(ModifierBadge)),
          findsNWidgets(2));
      expect(
          find.descendant(of: row, matching: find.text('Mot compte double ×1')),
          findsOneWidget);
      expect(
          find.descendant(of: row, matching: find.text('2 tirages par manche')),
          findsOneWidget);
      expect(find.textContaining('Mot à l'), findsNothing,
          reason: 'pas la liste du pool de tirage');

      await tester.tap(
          find.descendant(of: row, matching: find.text('Une seule réponse')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Compris'), findsOneWidget);
    });

    testWidgets('fiche de la paire Bruitages / drap : le texte de la paire',
        (tester) async {
      await pumpList(tester, const Size(390, 844));
      await select(tester, 'Mimeur expert');
      await tester.tap(find.textContaining('Bruitages seulement'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Gestes et bruits sous le drap, sans parler.'),
          findsOneWidget);
    });
  });

  group('Icônes', () {
    test('chaque ensemble fourni a la sienne, toutes différentes', () {
      final icons = kProvidedEnsembles.map(ensembleIcon).toSet();
      expect(icons, hasLength(kProvidedEnsembles.length));
    });

    IconData iconOf(FiestaRules rules) =>
        ensembleIcon(FiestaEnsemble(id: 'mine', rules: rules));

    test('perso avec tirage : dé', () {
      expect(
          iconOf(FiestaRules(
            drawCount: 1,
            allCount: 3,
            modifiers: {'reversed': const ModifierSetting(draw: true)},
          )),
          Icons.casino_outlined);
    });

    test('perso sans tirage, avec toute forme de cartouche : éclair', () {
      for (final rules in [
        FiestaRules(modifiers: {
          'double_points': const ModifierSetting(charges: 1),
        }),
        FiestaRules(allCount: 1),
        FiestaRules(trailingCount: 1),
        FiestaRules(balance: true),
        FiestaRules(challenges: true),
      ]) {
        expect(iconOf(rules), Icons.bolt);
      }
    });

    test('perso sinon, et perso sans aucune règle : couronne', () {
      expect(
          iconOf(FiestaRules(modifiers: {
            'one_answer': const ModifierSetting(always: true),
          })),
          Icons.emoji_events_outlined);
      expect(iconOf(FiestaRules()), Icons.emoji_events_outlined);
    });
  });

  group('Bas de liste', () {
    testWidgets('compteur dans « Créer un ensemble »', (tester) async {
      await pumpList(tester, const Size(390, 844),
          mine: [FiestaRules(ensembleName: 'Mien', allCount: 1)]);
      expect(find.text('Créer un ensemble · 1 / 10', skipOffstage: false),
          findsOneWidget);
      expect(find.text('PRÊTS À JOUER', skipOffstage: false), findsNothing);
    });

    testWidgets('liste pleine : l\'alerte et le compteur, plus de création',
        (tester) async {
      await pumpList(tester, const Size(360, 640), mine: tenMine());
      expect(find.textContaining('Créer un ensemble', skipOffstage: false),
          findsNothing);
      expect(find.textContaining('Limite de 10 ensembles', skipOffstage: false),
          findsOneWidget);
      expect(find.text('10 / 10', skipOffstage: false), findsOneWidget);
    });

    testWidgets(
        'brouillon : « Reprendre », avec le compteur, même liste pleine',
        (tester) async {
      FiestaEnsemblesScreen.drafts[FiestaEnsemblesScreen.newDraftKey] =
          FiestaRules(ensembleName: 'x');
      addTearDown(FiestaEnsemblesScreen.drafts.clear);
      await pumpList(tester, const Size(360, 640), mine: tenMine());
      expect(find.text('Reprendre le brouillon · 10 / 10', skipOffstage: false),
          findsOneWidget);
      expect(
          find.textContaining('Limite de', skipOffstage: false), findsNothing);
    });
  });
}
