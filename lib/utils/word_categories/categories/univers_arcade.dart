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
      WordWithDifficulty('Mewtwo', difficulty: 2),
      WordWithDifficulty('Mew', difficulty: 2),
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
      WordWithDifficulty('Rondoudou', difficulty: 1),
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
      WordWithDifficulty('Among Us', difficulty: 2),
      WordWithDifficulty('Pokémon', difficulty: 1),
      WordWithDifficulty('Spider-Man', difficulty: 2),

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
      WordWithDifficulty('Subway Surfers', difficulty: 2),
      WordWithDifficulty('Just Dance', difficulty: 1),
      WordWithDifficulty('Wii Sports', difficulty: 1),
      WordWithDifficulty('Pokemon GO', difficulty: 1),

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
      WordWithDifficulty('Bonne paye', difficulty: 2),
      WordWithDifficulty('Dominos', difficulty: 1),
      WordWithDifficulty('Mikado', difficulty: 1),

      // JEUX DE SOCIÉTÉ MODERNES - Moyen
      WordWithDifficulty('Cluedo', difficulty: 2),
      WordWithDifficulty('Risk', difficulty: 2),
      WordWithDifficulty('Trivial Pursuit', difficulty: 2),
      WordWithDifficulty('Puissance 4', difficulty: 1),
      WordWithDifficulty('Time\'s Up', difficulty: 2),
      WordWithDifficulty('Jungle Speed', difficulty: 2),
      WordWithDifficulty('Dobble', difficulty: 2),
      WordWithDifficulty('Pictionary', difficulty: 2),
      WordWithDifficulty('Taboo', difficulty: 2),
      WordWithDifficulty('Loups-garous', difficulty: 2),
      WordWithDifficulty('Mille bornes', difficulty: 2),

      // JEUX DE SOCIÉTÉ EXPERT - Difficile
      WordWithDifficulty('Catan', difficulty: 3),
      WordWithDifficulty('7 Wonders', difficulty: 3),
      WordWithDifficulty('Blanc-manger coco', difficulty: 3),
      WordWithDifficulty('Codenames', difficulty: 2),
      WordWithDifficulty('Splendor', difficulty: 3),
      WordWithDifficulty('Les aventuriers du rail', difficulty: 2),

      // CONSOLES DE JEUX - Facile
      WordWithDifficulty('Nintendo Switch', difficulty: 1),
      WordWithDifficulty('PlayStation', difficulty: 1),
      WordWithDifficulty('Xbox', difficulty: 1),
      WordWithDifficulty('Wii', difficulty: 1),
      WordWithDifficulty('Game Boy', difficulty: 1),
      WordWithDifficulty('Nintendo', difficulty: 1),

      // CONSOLES DE JEUX - Moyen
      WordWithDifficulty('Nintendo 64', difficulty: 3),
      WordWithDifficulty('GameCube', difficulty: 2),
      WordWithDifficulty('PlayStation 2', difficulty: 2),
      WordWithDifficulty('Nintendo DS', difficulty: 2),
      WordWithDifficulty('PSP', difficulty: 2),
      WordWithDifficulty('Xbox 360', difficulty: 2),

      // CONSOLES DE JEUX - Difficile
      WordWithDifficulty('Super Nintendo', difficulty: 3),
      WordWithDifficulty('Game Boy Advance', difficulty: 3),

      // PERSONNAGES DE JEUX VIDÉO - Facile
      WordWithDifficulty('Luigi', difficulty: 1),
      WordWithDifficulty('Peach', difficulty: 1),
      WordWithDifficulty('Bowser', difficulty: 1),
      WordWithDifficulty('Yoshi', difficulty: 1),
      WordWithDifficulty('Kirby', difficulty: 1),
      WordWithDifficulty('Link', difficulty: 1),
      WordWithDifficulty('Daisy', difficulty: 1),

      // PERSONNAGES DE JEUX VIDÉO - Moyen
      WordWithDifficulty('Crash Bandicoot', difficulty: 3),
      WordWithDifficulty('Lara Croft', difficulty: 3),
      WordWithDifficulty('Toad', difficulty: 2),
      WordWithDifficulty('Waluigi', difficulty: 2),
      WordWithDifficulty('Wario', difficulty: 2),

      // PERSONNAGES DE JEUX VIDÉO - Difficile
      WordWithDifficulty('Nathan Drake', difficulty: 3),

      // JEUX MOBILES POPULAIRES - Facile
      WordWithDifficulty('Candy Crush', difficulty: 1),
      WordWithDifficulty('Temple Run', difficulty: 1),
      WordWithDifficulty('Angry Birds', difficulty: 1),
      WordWithDifficulty('Fruit Ninja', difficulty: 1),

      // JEUX MOBILES POPULAIRES - Moyen
      WordWithDifficulty('Clash of Clans', difficulty: 2),
      WordWithDifficulty('Brawl Stars', difficulty: 2),
      WordWithDifficulty('Hay Day', difficulty: 3),

      // JEUX MOBILES POPULAIRES - Difficile
      WordWithDifficulty('Plants vs Zombies', difficulty: 3),

      // JEUX D'ARCADE CLASSIQUES - Facile
      WordWithDifficulty('Space Invaders', difficulty: 2),
      WordWithDifficulty('Street Fighter', difficulty: 2),
      WordWithDifficulty('Mortal Kombat', difficulty: 3),

      // JEUX D'ARCADE CLASSIQUES - Moyen
      WordWithDifficulty('Pong', difficulty: 2),
      WordWithDifficulty('Centipede', difficulty: 2),

      // MARIO KART - Facile
      WordWithDifficulty('Carapace rouge', difficulty: 1),
      WordWithDifficulty('Carapace verte', difficulty: 1),
      WordWithDifficulty('Banane', difficulty: 1),
      WordWithDifficulty('Champignon turbo', difficulty: 1),
      WordWithDifficulty('Étoile', difficulty: 1),

      // MARIO KART - Moyen
      WordWithDifficulty('Éclair', difficulty: 2),
      WordWithDifficulty('Carapace bleue', difficulty: 2),
      WordWithDifficulty('Bill Ball', difficulty: 2),

      // MARIO KART - Difficile
      WordWithDifficulty('Route Arc-en-ciel', difficulty: 2),
      WordWithDifficulty('Circuit Mario', difficulty: 3),
      WordWithDifficulty('Autodrome Toad', difficulty: 3),
      WordWithDifficulty('Château de Bowser', difficulty: 2),

      // SUPER SMASH BROS - Moyen
      WordWithDifficulty('Captain Falcon', difficulty: 3),
      WordWithDifficulty('Fox', difficulty: 3),

      // SUPER SMASH BROS - Difficile
      WordWithDifficulty('Marth', difficulty: 3),
      WordWithDifficulty('Roy', difficulty: 3),
      WordWithDifficulty('Falco', difficulty: 3),
      WordWithDifficulty('Meta Knight', difficulty: 3),
      WordWithDifficulty('Lucario', difficulty: 3),

      // JEUX DE COURSES - Facile
      WordWithDifficulty('Need for Speed', difficulty: 2),
      WordWithDifficulty('Gran Turismo', difficulty: 2),

      // JEUX DE COURSES - Moyen
      WordWithDifficulty('Forza', difficulty: 3),

      // JEUX DE COURSES - Difficile
      WordWithDifficulty('Trackmania', difficulty: 3),

      // BATTLE ROYALE - Facile
      WordWithDifficulty('Fall Guys', difficulty: 3),


      // OBJETS/ITEMS DE JEUX - Facile
      WordWithDifficulty('Champignon', difficulty: 1),
      WordWithDifficulty('Pièce d\'or', difficulty: 1),
      WordWithDifficulty('Cœur', difficulty: 1),
      WordWithDifficulty('Coffre', difficulty: 1),
      WordWithDifficulty('Épée', difficulty: 1),
      WordWithDifficulty('Bouclier', difficulty: 1),
      WordWithDifficulty('Bombe', difficulty: 1),
      WordWithDifficulty('Anneau', difficulty: 1),
      WordWithDifficulty('Clé', difficulty: 1),
      WordWithDifficulty('Gemme', difficulty: 1),

      // OBJETS/ITEMS DE JEUX - Moyen
      WordWithDifficulty('PokéBall', difficulty: 2),
      WordWithDifficulty('Potion', difficulty: 1),
      WordWithDifficulty('Épée de légende', difficulty: 3),
      WordWithDifficulty('Triforce', difficulty: 3),
      WordWithDifficulty('Ocarina', difficulty: 3),
      WordWithDifficulty('Arc', difficulty: 1),
      WordWithDifficulty('Flèche', difficulty: 1),
      WordWithDifficulty('Armure', difficulty: 1),
      WordWithDifficulty('Casque', difficulty: 1),

      // OBJETS/ITEMS DE JEUX - Difficile
      WordWithDifficulty('Grappin', difficulty: 3),

      // ENNEMIS ET BOSS - Facile
      WordWithDifficulty('Goomba', difficulty: 3),
      WordWithDifficulty('Koopa', difficulty: 3),
      WordWithDifficulty('Zombie', difficulty: 2),
      WordWithDifficulty('Squelette', difficulty: 1),
      WordWithDifficulty('Fantôme', difficulty: 1),

      // ENNEMIS ET BOSS - Moyen
      WordWithDifficulty('Roi Boo', difficulty: 3),

      // ENNEMIS ET BOSS - Difficile
      WordWithDifficulty('Ganondorf', difficulty: 3),

      // JEUX INDÉPENDANTS - Moyen
      WordWithDifficulty('Terraria', difficulty: 3),

      // JEUX INDÉPENDANTS - Difficile
      WordWithDifficulty('Isaac', difficulty: 3),

      // JEUX DE CARTES - Facile
      WordWithDifficulty('Pokémon', difficulty: 1),
      // JEUX DE CARTES - Moyen
      WordWithDifficulty('Hearthstone', difficulty: 3),
      WordWithDifficulty('Yu-Gi-Oh', difficulty: 2),

      // JEUX DE CARTES - Difficile
      WordWithDifficulty('Magic', difficulty: 3),
      WordWithDifficulty('Slay the Spire', difficulty: 3),

      // JEUX D'HORREUR - Facile
      WordWithDifficulty('Resident Evil', difficulty: 3),

      // JEUX D'HORREUR - Difficile
      WordWithDifficulty('The Last of Us', difficulty: 3),
  ],
);
