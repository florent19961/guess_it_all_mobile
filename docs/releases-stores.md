# Releases & stores

Ce que veut dire « mettre en prod » sur ce projet, et les gotchas de la mise à jour forcée.
Le runbook de release lui-même vit dans la skill **`guessitall-workflow` §Release**.

## Identifiants

| Plateforme | Identifiant |
|------------|-------------|
| Android | `com.guessitall.guess_it_all_mobile` |
| iOS | `6756429415` |

Version courante : voir `pubspec.yaml` (`version: X.Y.Z+N`).

## Le modèle de release

Il n'y a **pas de branche de prod**. `main` est le tronc ; ce qui est « en prod » est un **build
soumis au store**, matérialisé par un **tag `vX.Y.Z+N`** posé sur `main` au moment de la soumission.

Conséquences directes :

- Un closeout de story ne bump **jamais** `pubspec.yaml` et ne pousse **jamais** de tag.
- Le **build number `+N` doit STRICTEMENT augmenter** : les stores refusent un build déjà soumis.
  Un `+N` réutilisé se solde par un rejet à l'upload, après le build — donc tard.
- Une release ne se prépare que sur un `main` vert (`scripts/run-full-suite.sh`).

## Mise à jour forcée (`upgrader`)

Le package `upgrader` (^11.5.1) affiche un popup natif — Cupertino sur iOS, Material sur Android —
quand une version plus récente est disponible sur le store.

Configuration dans `lib/app.dart` :

```dart
static final _upgrader = Upgrader(
  storeController: UpgraderStoreController(
    onAndroid: () => UpgraderPlayStore(),
    oniOS: () => UpgraderAppStore(),
  ),
  languageCode: 'fr',
);

UpgradeAlert(
  upgrader: _upgrader,
  dialogStyle: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
      ? UpgradeDialogStyle.cupertino
      : UpgradeDialogStyle.material,
  child: ...,
)
```

**Gotchas payés :**

- `dialogStyle` est un paramètre de **`UpgradeAlert`**, pas de `Upgrader`.
- Utiliser `kIsWeb` + `defaultTargetPlatform` (`package:flutter/foundation.dart`) — **pas**
  `Platform.isIOS` de `dart:io`, qui ne fonctionne pas sur web.
- Depuis upgrader 11.5.1, `UpgraderAppStore` détecte l'App ID automatiquement via le bundle
  identifier — inutile de le passer à la main.

## 🔴 Ce que la mise à jour forcée implique pour le code

`upgrader` pousse **tout le parc** vers la dernière version publiée. Une version qui part en store
devient donc, à court terme, la version que **tout le monde** a.

Corollaire dur : **un bug de persistance embarqué dans une release est irrattrapable** sur les
données déjà écrites sur les téléphones. C'est la raison pour laquelle le schéma
`SharedPreferences` (`guessItAll_*`) est classé au tier risqué dans `guessitall-workflow` — au même
titre que la money sur un projet e-commerce. Tout changement de **forme** d'une clé stockée exige
une migration explicite, pas un « ça repartira de zéro ».

## Build

```bash
flutter build appbundle    # Android → Play Console
flutter build ipa          # iOS → App Store Connect
```

Une entrée datée dans `docs/tracking_evolution.md` clôt toute release.
