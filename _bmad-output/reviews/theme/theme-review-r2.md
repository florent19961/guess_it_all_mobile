# Revue Codex r2 — feat/theme-couleurs (copie relayée par la session principale)

Ratios r1 validés (8,33 / 10,31 / 5,87).

1. **MAJOR** `lib/theme/app_theme.dart:75-83` : les résolveurs ne testent que
   `WidgetState.selected`, donc un Switch désactivé (`onChanged` null) a les mêmes couleurs qu'un
   actif. → Ajouter la branche `WidgetState.disabled` (pouce et piste à ~38 % d'opacité, comme
   Material, ou gray600/gray700 : visiblement inactif).
