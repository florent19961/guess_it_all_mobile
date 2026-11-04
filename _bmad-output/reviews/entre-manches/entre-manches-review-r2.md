# Revue Codex entre-manches r2

Verdict : **READY**. Aucun finding.

- Le `semanticsLabel` est sur le `TextSpan` qui porte le nom, dans le même `Text.rich` que le signe et les secondes : TalkBack et VoiceOver lisent le libellé complet ; aucun `MergeSemantics`/`ExcludeSemantics` parent ne l'avale (`lib/widgets/fiesta/turn_time_cards.dart:89`).
- L'aide du rattrapage (`lib/widgets/help/help_content.dart:400`) décrit bonus et malus et la règle « seulement le 1er tour hors continuation ».
- Aucune régression.
