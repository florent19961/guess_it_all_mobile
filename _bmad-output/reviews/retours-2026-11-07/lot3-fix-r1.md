# Lot 3, corrections du round 1

Commit de tête : `3909153` (poussé sur `feat/retours-tour-icones`). Rapport : `lot3-review-r1.md`.

## Findings

| Finding | Décision | Preuve |
|---|---|---|
| MAJOR, émoji qui suit la taille de texte système | Corrigé : `textScaler: TextScaler.noScaling` dans `_glyph()` | `lib/widgets/fiesta/modifier_badge.dart`, test « l'émoji reste dans sa boîte » |
| MAJOR, `IntrinsicHeight` étire la rangée à grande police | Corrigé : `SizedBox(height: 114)`, contenu de Passer dans `FittedBox(fit: BoxFit.scaleDown)` | `lib/widgets/common/turn_play_widgets.dart`, test « Passer (gratuit) : la rangée reste à 114 px » |

Trouvé garde son rendu : padding 33 + icône 48 = 114 px, exactement la hauteur fixe. À taille de texte normale, le contenu de
Passer tient dans la hauteur et `scaleDown` ne l'agrandit pas : rendu inchangé.

## Tests

Ajouté : `test/widgets/turn_large_text_test.dart`, 3 cas à `TextScaler.linear(2)`.
- Passer « (gratuit) » : rouge avant le correctif (`Expected: <114> Actual: <126.0>`).
- Passer grisé : passait déjà avant le correctif. Il garde la hauteur de cet état, demandé par l'orchestrateur, mais ne reproduit pas le bug.
- Émoji : rouge sans `noScaling` (`Expected: <= 40 Actual: <58.0>`). Il lit `RenderParagraph.textSize` : une première version
  sur `getSize` passait à tort, la boîte contraignant le paragraphe.

Retiré : aucun.

## Suite complète

`scripts/run-full-suite.sh` : code de sortie 0, format 174 fichiers (0 modifié), `+583: All tests passed!`.

Non vérifié : le rendu réel de l'émoji et le rétrécissement sur téléphone à grande police (ni iOS ni Android ne tournent ici).

## Patch incrémental

```diff
diff --git a/lib/widgets/common/turn_play_widgets.dart b/lib/widgets/common/turn_play_widgets.dart
index a3a1fa2..4174e5b 100644
--- a/lib/widgets/common/turn_play_widgets.dart
+++ b/lib/widgets/common/turn_play_widgets.dart
@@ -40,7 +40,10 @@ class TurnWordText extends StatelessWidget {
       );
 }
 
-/// Les boutons Passer (rouge) et Trouvé (cyan) du tour, de même hauteur.
+/// Hauteur des boutons du tour : celle de Trouvé (padding 33 + icône 48).
+const _buttonsHeight = 114.0;
+
+/// Les boutons Passer (rouge) et Trouvé (cyan) du tour, de même hauteur fixe.
 class TurnActionButtons extends StatefulWidget {
   /// `null` = bouton grisé (pause, `no_pass`, plus de mot à passer…).
   final VoidCallback? onPass;
@@ -130,7 +133,8 @@ class _TurnActionButtonsState extends State<TurnActionButtons>
     return Stack(
       clipBehavior: Clip.none,
       children: [
-        IntrinsicHeight(
+        SizedBox(
+          height: _buttonsHeight,
           child: Row(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
@@ -148,7 +152,8 @@ class _TurnActionButtonsState extends State<TurnActionButtons>
                       color: canPass ? AppColors.error : AppColors.gray700,
                       borderRadius: BorderRadius.circular(20),
                     ),
-                    child: pass,
+                    // Grande police : Passer rétrécit, la rangée ne bouge pas.
+                    child: FittedBox(fit: BoxFit.scaleDown, child: pass),
                   ),
                 ),
               ),
diff --git a/lib/widgets/fiesta/modifier_badge.dart b/lib/widgets/fiesta/modifier_badge.dart
index 94eb67f..f48ef53 100644
--- a/lib/widgets/fiesta/modifier_badge.dart
+++ b/lib/widgets/fiesta/modifier_badge.dart
@@ -60,8 +60,9 @@ const Map<String, String> _emojiIcons = {
 const Set<String> _slashedIcons = {'mime_no_arms', 'mime_eyes_closed'};
 
 /// L'icône d'un modificateur : boîte carrée de [size], contenu centré. Seul
-/// point d'affichage des icônes. Un émoji ne dépend ni de la police de l'app ni
-/// des métriques de sa ligne, d'où un centrage commun à toutes les tailles.
+/// point d'affichage des icônes. Un émoji ne dépend ni de la police de l'app, ni
+/// des métriques de sa ligne, ni de la taille de texte système : même centrage à
+/// toutes les tailles, et `slash.png` le barre toujours.
 /// [color] ne teinte que le repli texte ([kModifierIcons]).
 class ModifierIcon extends StatelessWidget {
   final String id;
@@ -84,6 +85,7 @@ class ModifierIcon extends StatelessWidget {
     final fontSize = size * 0.72;
     return Text(
       text,
+      textScaler: TextScaler.noScaling,
       maxLines: 1,
       softWrap: false,
       overflow: TextOverflow.visible,
diff --git a/test/widgets/turn_large_text_test.dart b/test/widgets/turn_large_text_test.dart
new file mode 100644
index 0000000..95b710d
--- /dev/null
+++ b/test/widgets/turn_large_text_test.dart
@@ -0,0 +1,39 @@
+import 'package:flutter/material.dart';
+import 'package:flutter/rendering.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:guess_it_all_mobile/widgets/common/turn_play_widgets.dart';
+import 'package:guess_it_all_mobile/widgets/fiesta/modifier_badge.dart';
+
+/// [child] à la taille de texte système de 200 %.
+Future<void> pumpLargeText(WidgetTester tester, Widget child) =>
+    tester.pumpWidget(MaterialApp(
+      builder: (context, _) => MediaQuery(
+        data: MediaQuery.of(context)
+            .copyWith(textScaler: const TextScaler.linear(2)),
+        child: Material(child: Center(child: child)),
+      ),
+    ));
+
+void main() {
+  for (final (state, onPass, detail) in [
+    ('(gratuit)', () {}, '(gratuit)'),
+    ('grisé', null, null),
+  ]) {
+    testWidgets('texte à 200 %, Passer $state : la rangée reste à 114 px',
+        (tester) async {
+      await pumpLargeText(
+          tester,
+          TurnActionButtons(
+              onPass: onPass, onGuessed: () {}, passDetail: detail));
+      expect(tester.getSize(find.byType(TurnActionButtons)).height, 114);
+      expect(tester.takeException(), isNull, reason: 'aucun débordement');
+    });
+  }
+
+  testWidgets('texte à 200 % : l\'émoji reste dans sa boîte', (tester) async {
+    await pumpLargeText(tester, const ModifierIcon('mime_no_arms', size: 40));
+    // La taille du texte, pas celle du paragraphe que la boîte contraint.
+    final emoji = tester.renderObject<RenderParagraph>(find.text('💪'));
+    expect(emoji.textSize.height, lessThanOrEqualTo(40));
+  });
+}
```
