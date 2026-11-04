# theme/

Theme visuel de l'application. **Fichier unique : `app_theme.dart`.**

## 🔴 La source de verite est le code, pas ce fichier

Ce document decrivait une palette qui n'existe pas dans l'app : fond noir
`#0A0A0A`, rose vif `#FF3B7F`, cyan electrique `#00E5FF`, « 5 niveaux de gris ».
Le code dit tout autre chose — fond bleu ardoise, rose poudre, vert d'eau, 4 gris.
Un agent qui faisait confiance a cette page ecrivait donc du code hors-charte en
croyant la respecter.

**Ne recopie jamais une valeur de couleur ici.** Pour connaitre la palette :

```bash
grep -n "static const Color" lib/theme/app_theme.dart
```

## Ce que le code ne dit pas tout seul

- L'app est en **sombre uniquement** : `AppTheme.darkTheme` est le seul theme,
  il n'y a ni variante claire ni bascule.
- `backgroundCard` est le **meme ton que `backgroundMain` en semi-transparent**
  (alpha `0x99`) : les cartes ne sont pas une couleur a part, elles laissent
  passer le fond etoile (`widgets/effects/shooting_stars.dart`).
- `error` vaut exactement `primaryPinkDark` : l'erreur ne crie pas, le registre
  du jeu reste doux. Ne « corrige » pas ca en rouge franc.
- Les 4 couleurs d'equipe reprennent primary/secondary puis ajoutent violet et
  ambre. Au-dela de 4 equipes, l'affichage **cycle** (`% length`) — c'est un
  choix, pas un oubli.
- Le `colorScheme` est construit **a la main** depuis `AppColors` (constructeur
  `ColorScheme(...)` nu, jamais `fromSeed` ni `ColorScheme.dark()`, qui
  ramenent le violet Material). Un widget Material non style prend donc la
  charte. Le `switchTheme` (pouce blanc, piste turquoise / `gray700`, sans
  contour) et le `textSelectionTheme` (turquoise) completent.

## Typographie

- **Bangers** : titres — `AppTextStyles.title({fontSize})` et
  `subtitle({fontSize})`, des fonctions (ombres portees), pas des constantes.
- **Poppins** : corps et libelles — `body`, `bodySmall`, `label`, constantes.
