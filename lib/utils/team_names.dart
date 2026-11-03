import 'dart:math';

/// Noms d'équipe drôles, tirés à la création des équipes. Le joueur peut
/// toujours renommer à la main. Tout public, sans nom de marque.
const List<String> kFunnyTeamNames = [
  'Les Mimes Fous',
  'Les Devins du Dimanche',
  'Les Tchatcheurs',
  'Les Muets Sauvages',
  'Les Langues Pendues',
  'Les Cerveaux en Folie',
  'Les Mots Croisés',
  'Les Bavards Masqués',
  'Les Devineurs Fous',
  'Les Pros du Charabia',
  'Les Rois du Mime',
  'Les Moulins à Paroles',
  'Les Têtes en l\'Air',
  'Les Sabliers Pressés',
  'Les Indices Foireux',
  'Les Génies du Salon',
  'Les Fous du Chrono',
  'Les Gestes Barrés',
  'Les Mains Baladeuses',
  'Les Pipelettes',
  'Les Supers Souffleurs',
  'Les Lapins Pressés',
  'Les Perroquets Malins',
  'Les Chouettes Futées',
  'Les Pingouins Bavards',
  'Les Ninjas du Mot',
  'Les Mystères Ambulants',
  'Les Charades Vivantes',
  'Les Écureuils Agités',
  'Les Zèbres Rigolos',
];

/// [count] noms distincts, au hasard.
List<String> drawTeamNames(int count, [Random? random]) {
  assert(count <= kFunnyTeamNames.length);
  return (List.of(kFunnyTeamNames)..shuffle(random)).take(count).toList();
}
