import 'dart:async';

/// Orchestration du démarrage de l'application.
///
/// 🔴 **INVARIANT : le premier frame ne dépend JAMAIS du réseau.**
///
/// Historique — pourquoi ce fichier existe : `main()` attendait
/// `FirebaseSyncService().initialize()`, qui se termine par la vidange complète
/// de la queue Firestore, avant d'appeler `runApp()`. La Future d'un `set()`
/// Firestore ne se résout qu'à l'ACK serveur : derrière un portail captif (où
/// `ConnectivityService` rapporte pourtant « connecté », puisqu'il ne teste que
/// le TYPE d'interface), elle ne se résout ni en succès ni en erreur. Résultat :
/// splash native figée à vie, dès qu'une partie avait été jouée hors ligne.
///
/// La séparation est donc sémantique, pas cosmétique :
/// - **[localTasks]** — disque, assets, préférences. Attendues, parce que l'app
///   en a besoin pour afficher un premier écran cohérent (mots chargés, partie en
///   cours restaurée). Bornées par construction : pas d'I/O réseau.
/// - **[networkTasks]** — lancées en arrière-plan, jamais attendues. Leur durée
///   est hors de notre contrôle.
///
/// Dans les deux cas, l'échec d'une tâche est absorbé : ce sont des services
/// optionnels (analytics, sync), et aucun ne justifie d'empêcher une soirée de
/// commencer.
Future<void> runStartupTasks({
  required List<Future<void> Function()> localTasks,
  required List<Future<void> Function()> networkTasks,
}) async {
  for (final task in localTasks) {
    await _guard(task);
  }

  // Volontairement NON attendues — c'est tout l'objet de cette fonction.
  for (final task in networkTasks) {
    unawaited(_guard(task));
  }
}

/// Exécute [task] en absorbant son échec.
///
/// Indispensable côté réseau : une Future d'erreur sans handler devient une
/// *unhandled async error* qui remonte à la zone et peut faire tomber l'app en
/// release — précisément le mode de défaillance qu'un `catchError` sans `return`
/// produisait sur `markForSync`.
Future<void> _guard(Future<void> Function() task) async {
  try {
    await task();
  } catch (_) {
    // Service optionnel indisponible : on continue.
  }
}
