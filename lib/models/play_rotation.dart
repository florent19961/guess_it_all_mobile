/// Rotation des équipes et des joueurs au fil des tours.
///
/// 🔴 **Pourquoi ce fichier existe.** L'ordre de jeu était *matérialisé* : la
/// permutation des équipes était répétée **1000 fois** dans une liste, idem pour
/// les joueurs de chaque équipe. Avec 4 équipes et 20 joueurs, ça fait ~24 000
/// entiers — ré-écrits sur disque à CHAQUE sauvegarde d'état, c'est-à-dire à
/// chaque mot deviné, chaque passe, chaque tour. Environ 95 % du blob persisté
/// n'était que du remplissage périodique.
///
/// Or une liste périodique n'a pas besoin d'être stockée : elle se dérive. Ces
/// fonctions n'utilisent que **le cycle de base** (une permutation, une seule
/// fois) et un modulo.
///
/// ⚠️ **Rétro-compatible avec les parties déjà sauvegardées.** Une liste
/// répétée 1000 fois reste périodique de période `cycleLength` : indexer
/// `% cycleLength` donne le même résultat sur l'ancien format que sur le
/// nouveau. Aucune migration n'est nécessaire.
library;

/// Index de l'équipe qui joue au tour [turnIndex].
///
/// [teamPlayOrder] peut être le cycle seul ou l'ancienne liste répétée :
/// [cycleLength] (le nombre d'équipes) est ce qui fait foi.
int teamIndexAtTurn({
  required List<int> teamPlayOrder,
  required int cycleLength,
  required int turnIndex,
}) {
  if (teamPlayOrder.isEmpty || cycleLength <= 0) return 0;
  final period = cycleLength.clamp(1, teamPlayOrder.length);
  return teamPlayOrder[turnIndex % period];
}

/// Combien de fois l'équipe du tour [turnIndex] a joué, ce tour-ci inclus.
///
/// ⚠️ **Précondition : le cycle de base est une PERMUTATION** — chaque équipe y
/// apparaît exactement une fois. C'est ce que garantit `_generatePlayOrder`
/// (mélange d'indices distincts). Sur un cycle où une équipe apparaîtrait deux
/// fois, cette formule serait fausse : le comptage par balayage et la division
/// entière divergeraient. La suite de tests le vérifie en comparant les deux
/// implémentations sur toutes les tailles de partie possibles.
///
/// Le cycle de base étant une **permutation** (chaque équipe exactement une fois
/// par tour de table), l'équipe qui joue au tour `n` occupe toujours la position
/// `n % période` : elle a donc joué `n ~/ période + 1` fois. C'est l'équivalent
/// exact du comptage par balayage de l'ancienne implémentation, en O(1).
int teamPlayCountAtTurn({required int cycleLength, required int turnIndex}) {
  if (cycleLength <= 0) return 1;
  return turnIndex ~/ cycleLength + 1;
}

/// Index, dans son équipe, du joueur qui fait deviner au tour [turnIndex].
int playerIndexAtTurn({
  required List<int> playerOrderForTeam,
  required int cycleLength,
  required int turnIndex,
}) {
  if (playerOrderForTeam.isEmpty) return 0;
  final playCount =
      teamPlayCountAtTurn(cycleLength: cycleLength, turnIndex: turnIndex);
  return playerOrderForTeam[(playCount - 1) % playerOrderForTeam.length];
}
