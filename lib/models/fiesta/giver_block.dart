import 'symmetric_draw.dart';

/// Le piège d'« Interdit de faire deviner » : la phrase que découvre le joueur
/// bloqué après son décompte.

/// Graine de la phrase : `(gameId, tour)`, DÉTERMINISTE pour qu'une app tuée
/// remontre la même.
int giverBlockSeed(String gameId, int turnIndex) =>
    drawSeed('$gameId#giverBlock', turnIndex);

const List<String Function(String blocked, String blocker)> _phrases = [
  _sorry,
  _afraid,
  _countdown,
  _putDown,
  _thanks,
  _bench,
  _calm,
  _nice,
];

String _sorry(String b, String a) =>
    'Sorry $b, la vie est injuste : $a a décidé que tu ne jouerais pas ce tour.';
String _afraid(String b, String a) =>
    '$a a eu peur de toi, $b. Tu ne joues pas ce tour.';
String _countdown(String b, String a) =>
    '3, 2, 1… non. $a vient d\'annuler ton tour, $b.';
String _putDown(String b, String a) =>
    'Pose ce téléphone, $b. $a ne veut pas te voir jouer.';
String _thanks(String b, String a) =>
    'Tout ce suspense pour rien, $b. Merci qui ? Merci $a.';
String _bench(String b, String a) =>
    'Trop de talent, $b. $a préfère te garder sur le banc.';
String _calm(String b, String a) => 'On se calme, $b. $a a dit non.';
String _nice(String b, String a) =>
    'Joli réglage, $b. Dommage : $a offre ton tour à quelqu\'un d\'autre.';

String giverBlockPhrase({
  required int seed,
  required String blocked,
  required String blocker,
}) =>
    _phrases[seed % _phrases.length](blocked, blocker);
