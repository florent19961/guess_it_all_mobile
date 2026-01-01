import '../models.dart';

const categoryUniversArcade = WordCategory(
  id: 'univers_arcade',
  name: 'Arcade',
  icon: '🎮',
  words: [

      // POKÉMON GÉNÉRATION 1 - Facile
      WordWithDifficulty('Pikachu', difficulty: 1),
      WordWithDifficulty('Dracaufeu', difficulty: 1),
      WordWithDifficulty('Bulbizarre', difficulty: 1),
      WordWithDifficulty('Salamèche', difficulty: 1),
      WordWithDifficulty('Carapuce', difficulty: 1),
      WordWithDifficulty('Ronflex', difficulty: 3),
      WordWithDifficulty('Évoli', difficulty: 3),
      WordWithDifficulty('Mewtwo', difficulty: 3),
      WordWithDifficulty('Mew', difficulty: 3),
      WordWithDifficulty('Rattata', difficulty: 3),
      WordWithDifficulty('Roucool', difficulty: 3),
      WordWithDifficulty('Chenipan', difficulty: 3),

      // POKÉMON GÉNÉRATION 1 - Moyen
      WordWithDifficulty('Florizarre', difficulty: 3),
      WordWithDifficulty('Tortank', difficulty: 3),
      WordWithDifficulty('Raichu', difficulty: 3),
      WordWithDifficulty('Aquali', difficulty: 3),
      WordWithDifficulty('Voltali', difficulty: 3),
      WordWithDifficulty('Pyroli', difficulty: 3),
      WordWithDifficulty('Rondoudou', difficulty: 2),
      WordWithDifficulty('Mélofée', difficulty: 3),
      WordWithDifficulty('Psykokwak', difficulty: 3),
      WordWithDifficulty('Magicarpe', difficulty: 3),
      WordWithDifficulty('Léviator', difficulty: 3),
      WordWithDifficulty('Dracolosse', difficulty: 3),
      WordWithDifficulty('Piafabec', difficulty: 3),
      WordWithDifficulty('Sabelette', difficulty: 3),
      WordWithDifficulty('Goupix', difficulty: 3),
      WordWithDifficulty('Ramoloss', difficulty: 3),
      WordWithDifficulty('Soporifik', difficulty: 3),

      // POKÉMON LÉGENDAIRES ET GÉNÉRATIONS SUIVANTES - Moyen
      WordWithDifficulty('Lugia', difficulty: 3),
      WordWithDifficulty('Ho-Oh', difficulty: 3),
      WordWithDifficulty('Rayquaza', difficulty: 3),
      WordWithDifficulty('Kyogre', difficulty: 3),
      WordWithDifficulty('Groudon', difficulty: 3),
      WordWithDifficulty('Dialga', difficulty: 3),
      WordWithDifficulty('Palkia', difficulty: 3),
      WordWithDifficulty('Giratina', difficulty: 3),

      // POKÉMON LÉGENDAIRES - Difficile
      WordWithDifficulty('Artikodin', difficulty: 3),
      WordWithDifficulty('Électhor', difficulty: 3),
      WordWithDifficulty('Sulfura', difficulty: 3),
      WordWithDifficulty('Suicune', difficulty: 3),
      WordWithDifficulty('Entei', difficulty: 3),

      // CLASH ROYALE TROUPES - Facile
      WordWithDifficulty('Chevalier', difficulty: 2),
      WordWithDifficulty('Archers', difficulty: 3),
      WordWithDifficulty('Géant', difficulty: 2),
      WordWithDifficulty('P.E.K.K.A', difficulty: 3),
      WordWithDifficulty('Dragon', difficulty: 2),
      WordWithDifficulty('Sorcier', difficulty: 2),
      WordWithDifficulty('Squelettes', difficulty: 2),
      WordWithDifficulty('Gobelins', difficulty: 3),

      // CLASH ROYALE TROUPES - Moyen
      WordWithDifficulty('Prince', difficulty: 2),
      WordWithDifficulty('Princesse', difficulty: 2),
      WordWithDifficulty('Valkyrie', difficulty: 3),
      WordWithDifficulty('Golem', difficulty: 3),
      WordWithDifficulty('Ballon', difficulty: 2),
      WordWithDifficulty('Méga chevalier', difficulty: 3),
      WordWithDifficulty('Bûcheron', difficulty: 2),
      WordWithDifficulty('Sorcière', difficulty: 2),
      WordWithDifficulty('Barbare', difficulty: 2),
      WordWithDifficulty('Mini P.E.K.K.A', difficulty: 3),
      WordWithDifficulty('Mousquetaire', difficulty: 2),

      // CLASH ROYALE TROUPES - Difficile
      WordWithDifficulty('Électro-géant', difficulty: 3),
      WordWithDifficulty('Archer magique', difficulty: 3),
      WordWithDifficulty('Mineur', difficulty: 3),
      WordWithDifficulty('Bandit', difficulty: 3),
      WordWithDifficulty('Fantôme royal', difficulty: 3),
      WordWithDifficulty('Golem de glace', difficulty: 3),
      WordWithDifficulty('Lavahound', difficulty: 3),
      WordWithDifficulty('Boulet de canon', difficulty: 3),
      WordWithDifficulty('Garde royale', difficulty: 3),

      // CLASH ROYALE SORTS - Moyen
      WordWithDifficulty('Boule de feu', difficulty: 3),
      WordWithDifficulty('Flèches', difficulty: 2),
      WordWithDifficulty('Zap', difficulty: 3),
      WordWithDifficulty('Foudre', difficulty: 2),
      WordWithDifficulty('Rage', difficulty: 2),
      WordWithDifficulty('Gel', difficulty: 2),

      // CLASH ROYALE SORTS - Difficile
      WordWithDifficulty('Tornade', difficulty: 2),
      WordWithDifficulty('Clone', difficulty: 3),
      WordWithDifficulty('Guérison', difficulty: 2),
      WordWithDifficulty('Poison', difficulty: 2),
      WordWithDifficulty('Boule de neige', difficulty: 3),

      // JEUX VIDÉO CLASSIQUES - Facile
      WordWithDifficulty('Mario', difficulty: 1),
      WordWithDifficulty('Zelda', difficulty: 1),
      WordWithDifficulty('Minecraft', difficulty: 1),
      WordWithDifficulty('Fortnite', difficulty: 2),
      WordWithDifficulty('Sonic', difficulty: 2),
      WordWithDifficulty('Pac-Man', difficulty: 2),
      WordWithDifficulty('Tetris', difficulty: 1),
      WordWithDifficulty('Among Us', difficulty: 3),
      WordWithDifficulty('Pokémon', difficulty: 1),

      // JEUX VIDÉO POPULAIRES - Moyen
      WordWithDifficulty('GTA', difficulty: 3),
      WordWithDifficulty('Call of Duty', difficulty: 2),
      WordWithDifficulty('FIFA', difficulty: 1),
      WordWithDifficulty('Assassin\'s Creed', difficulty: 3),
      WordWithDifficulty('The Witcher', difficulty: 3),
      WordWithDifficulty('League of Legends', difficulty: 3),
      WordWithDifficulty('Animal Crossing', difficulty: 2),
      WordWithDifficulty('Super Smash Bros', difficulty: 3),
      WordWithDifficulty('Rocket League', difficulty: 3),
      WordWithDifficulty('Apex Legends', difficulty: 3),
      WordWithDifficulty('Sims', difficulty: 2),
      WordWithDifficulty('Subway Surfers', difficulty: 3),

      // JEUX VIDÉO CULTE - Difficile
      WordWithDifficulty('Donkey Kong', difficulty: 3),
      WordWithDifficulty('Final Fantasy', difficulty: 3),
      WordWithDifficulty('World of Warcraft', difficulty: 3),
      WordWithDifficulty('Dofus', difficulty: 1),
      WordWithDifficulty('Spyro', difficulty: 3),

      // JEUX DE SOCIÉTÉ CLASSIQUES - Facile
      WordWithDifficulty('Monopoly', difficulty: 1),
      WordWithDifficulty('Scrabble', difficulty: 1),
      WordWithDifficulty('Uno', difficulty: 1),
      WordWithDifficulty('Échecs', difficulty: 1),
      WordWithDifficulty('Dames', difficulty: 1),
      WordWithDifficulty('Petits chevaux', difficulty: 1),
      WordWithDifficulty('Bonne paye', difficulty: 3),

      // JEUX DE SOCIÉTÉ MODERNES - Moyen
      WordWithDifficulty('Cluedo', difficulty: 2),
      WordWithDifficulty('Risk', difficulty: 2),
      WordWithDifficulty('Trivial Pursuit', difficulty: 2),
      WordWithDifficulty('Puissance 4', difficulty: 2),
      WordWithDifficulty('Time\'s Up', difficulty: 2),
      WordWithDifficulty('Jungle Speed', difficulty: 2),
      WordWithDifficulty('Dobble', difficulty: 2),
      WordWithDifficulty('Pictionary', difficulty: 2),
      WordWithDifficulty('Taboo', difficulty: 2),
      WordWithDifficulty('Loups-garous', difficulty: 1),
      WordWithDifficulty('Mille bornes', difficulty: 3),

      // JEUX DE SOCIÉTÉ EXPERT - Difficile
      WordWithDifficulty('Catan', difficulty: 3),
      WordWithDifficulty('7 Wonders', difficulty: 3),
      WordWithDifficulty('Blanc-manger coco', difficulty: 3),
      WordWithDifficulty('Codenames', difficulty: 3),
      WordWithDifficulty('Splendor', difficulty: 3),
      WordWithDifficulty('Les aventuriers du rail', difficulty: 3),
    
  ],
);
