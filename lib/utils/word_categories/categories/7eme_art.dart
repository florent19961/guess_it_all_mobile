import '../models.dart';

const category7emeArt = WordCategory(
  id: '7eme_art',
  name: '7ème Art',
  icon: '🎬',
  words: [
    // FILMS CLASSIQUES - Facile
    WordWithDifficulty('Titanic', difficulty: 1),
    WordWithDifficulty('Avatar', difficulty: 1),
    WordWithDifficulty('Star Wars', difficulty: 1),
    WordWithDifficulty('Jurassic Park', difficulty: 1),
    WordWithDifficulty('Le Roi Lion', difficulty: 1),
    WordWithDifficulty('Harry Potter', difficulty: 1),
    WordWithDifficulty('Forrest Gump', difficulty: 2),
    WordWithDifficulty('Retour vers le futur', difficulty: 2),
    WordWithDifficulty('Indiana Jones', difficulty: 1),
    WordWithDifficulty('Pirates des Caraïbes', difficulty: 1),
    WordWithDifficulty('Transformers', difficulty: 2),
    WordWithDifficulty('Fast and Furious', difficulty: 1),
    WordWithDifficulty('Mission Impossible', difficulty: 1),
    WordWithDifficulty('James Bond', difficulty: 1),
    WordWithDifficulty('La La Land', difficulty: 2),
    WordWithDifficulty('E.T.', difficulty: 2),
    WordWithDifficulty('Les Dents de la Mer', difficulty: 1),
    WordWithDifficulty('Ghostbusters', difficulty: 2),
    WordWithDifficulty('King Kong', difficulty: 2),
    WordWithDifficulty('Godzilla', difficulty: 2),

    // FILMS CLASSIQUES - Moyen
    WordWithDifficulty('Le Parrain', difficulty: 2),
    WordWithDifficulty('Matrix', difficulty: 2),
    WordWithDifficulty('Inception', difficulty: 2),
    WordWithDifficulty('Gladiator', difficulty: 2),
    WordWithDifficulty('Le Seigneur des Anneaux', difficulty: 1),
    WordWithDifficulty('Pulp Fiction', difficulty: 2),
    WordWithDifficulty('Terminator', difficulty: 1),
    WordWithDifficulty('Alien', difficulty: 2),
    WordWithDifficulty('Rocky', difficulty: 2),
    WordWithDifficulty('Shrek', difficulty: 1),
    WordWithDifficulty('Interstellar', difficulty: 2),
    WordWithDifficulty('Top Gun', difficulty: 2),
    WordWithDifficulty('Le Loup de Wall Street', difficulty: 2),
    WordWithDifficulty('Gravity', difficulty: 2),
    WordWithDifficulty('Dune', difficulty: 2),
    WordWithDifficulty('Blade Runner', difficulty: 3),
    WordWithDifficulty('Mad Max', difficulty: 3),
    WordWithDifficulty('Apocalypse Now', difficulty: 2),
    WordWithDifficulty('Scarface', difficulty: 2),
    WordWithDifficulty('Taxi Driver', difficulty: 2),
    WordWithDifficulty('Reservoir Dogs', difficulty: 3),
    WordWithDifficulty('Kill Bill', difficulty: 2),
    WordWithDifficulty('Django Unchained', difficulty: 2),
    WordWithDifficulty('Le Prestige', difficulty: 2),

    // FILMS CLASSIQUES - Difficile
    WordWithDifficulty('Le Silence des Agneaux', difficulty: 3),
    WordWithDifficulty('Les Évadés', difficulty: 3),
    WordWithDifficulty('La Liste de Schindler', difficulty: 3),
    WordWithDifficulty('Il faut sauver le soldat Ryan', difficulty: 3),
    WordWithDifficulty('Fight Club', difficulty: 3),
    WordWithDifficulty('Seven', difficulty: 3),
    WordWithDifficulty('Shutter Island', difficulty: 3),
    WordWithDifficulty('The Truman Show', difficulty: 3),
    WordWithDifficulty('Eternal Sunshine', difficulty: 3),
    WordWithDifficulty('Whiplash', difficulty: 3),
    WordWithDifficulty('Gone Girl', difficulty: 3),
    WordWithDifficulty('No Country for Old Men', difficulty: 3),
    WordWithDifficulty('There Will Be Blood', difficulty: 3),
    WordWithDifficulty("2001 L'Odyssée de l'espace", difficulty: 3),
    WordWithDifficulty('Un Américain bien tranquille', difficulty: 3),
    WordWithDifficulty('La Vie est belle', difficulty: 3),
    WordWithDifficulty('Le Pont de la rivière Kwaï', difficulty: 3),
    WordWithDifficulty("Lawrence d'Arabie", difficulty: 3),
    WordWithDifficulty('Citizen Kane', difficulty: 3),

    // SUPER-HÉROS - Facile
    WordWithDifficulty('Batman', difficulty: 1),
    WordWithDifficulty('Superman', difficulty: 1),
    WordWithDifficulty('Spider-Man', difficulty: 1),
    WordWithDifficulty('Iron Man', difficulty: 1),
    WordWithDifficulty('Avengers', difficulty: 1),
    WordWithDifficulty('Thor', difficulty: 2),
    WordWithDifficulty('Hulk', difficulty: 1),
    WordWithDifficulty('X-Men', difficulty: 1),
    WordWithDifficulty('Les Gardiens de la Galaxie', difficulty: 2),
    WordWithDifficulty('Ant-Man', difficulty: 3),

    // SUPER-HÉROS - Moyen
    WordWithDifficulty('Black Panther', difficulty: 2),
    WordWithDifficulty('Joker', difficulty: 1),
    WordWithDifficulty('Captain America', difficulty: 1),
    WordWithDifficulty('Wonder Woman', difficulty: 1),
    WordWithDifficulty('Doctor Strange', difficulty: 3),
    WordWithDifficulty('Deadpool', difficulty: 3),
    WordWithDifficulty('Black Widow', difficulty: 2),
    WordWithDifficulty('Aquaman', difficulty: 2),
    WordWithDifficulty('Shazam', difficulty: 2),
    WordWithDifficulty('Venom', difficulty: 3),
    WordWithDifficulty('Eternals', difficulty: 3),

    // SUPER-HÉROS - Difficile
    WordWithDifficulty('Batman : The Dark Knight', difficulty: 2),
    WordWithDifficulty('Logan', difficulty: 3),
    WordWithDifficulty('Watchmen', difficulty: 3),
    WordWithDifficulty('V pour Vendetta', difficulty: 3),
    WordWithDifficulty('Kick-Ass', difficulty: 3),
    WordWithDifficulty('Hellboy', difficulty: 3),

    // DISNEY / PIXAR - Facile
    WordWithDifficulty('La Reine des Neiges', difficulty: 1),
    WordWithDifficulty('Toy Story', difficulty: 1),
    WordWithDifficulty('Nemo', difficulty: 1),
    WordWithDifficulty('Cendrillon', difficulty: 1),
    WordWithDifficulty('Aladdin', difficulty: 1),
    WordWithDifficulty('Vaiana', difficulty: 2),
    WordWithDifficulty('Raiponce', difficulty: 1),
    WordWithDifficulty('Mulan', difficulty: 1),
    WordWithDifficulty('La Belle et la Bête', difficulty: 1),
    WordWithDifficulty('Pocahontas', difficulty: 1),
    WordWithDifficulty('Cars', difficulty: 1),
    WordWithDifficulty('Blanche-Neige', difficulty: 1),
    WordWithDifficulty('La Petite Sirène', difficulty: 1),
    WordWithDifficulty('Dumbo', difficulty: 1),
    WordWithDifficulty('Bambi', difficulty: 1),

    // DISNEY / PIXAR - Moyen
    WordWithDifficulty('Ratatouille', difficulty: 2),
    WordWithDifficulty('Vice-Versa', difficulty: 1),
    WordWithDifficulty('Coco', difficulty: 1),
    WordWithDifficulty('Wall-E', difficulty: 2),
    WordWithDifficulty('Monstres et Cie', difficulty: 1),
    WordWithDifficulty('Les Indestructibles', difficulty: 1),
    WordWithDifficulty('Rebelle', difficulty: 2),
    WordWithDifficulty('Encanto', difficulty: 2),
    WordWithDifficulty('Zootopie', difficulty: 1),
    WordWithDifficulty('Là-haut', difficulty: 2),
    WordWithDifficulty('Dory', difficulty: 1),
    WordWithDifficulty('Luca', difficulty: 1),
    WordWithDifficulty('Alerte Rouge', difficulty: 2),
    WordWithDifficulty('Strange World', difficulty: 3),
    WordWithDifficulty('Raya', difficulty: 1),

    // DISNEY / PIXAR - Difficile
    WordWithDifficulty('La Princesse et la Grenouille', difficulty: 3),
    WordWithDifficulty('Atlantide', difficulty: 3),
    WordWithDifficulty('Hercule', difficulty: 1),
    WordWithDifficulty('Tarzan', difficulty: 1),
    WordWithDifficulty('Soul', difficulty: 2),
    WordWithDifficulty('Rox et Rouky', difficulty: 2),
    WordWithDifficulty('Dinosaure', difficulty: 1),
    WordWithDifficulty('Kuzco', difficulty: 2),
    WordWithDifficulty('La Planète au Trésor', difficulty: 3),
    WordWithDifficulty('Frère des Ours', difficulty: 3),

    // ANIMATION NON-DISNEY - Facile
    WordWithDifficulty('Kung Fu Panda', difficulty: 1),
    WordWithDifficulty('Madagascar', difficulty: 1),
    WordWithDifficulty('Les Minions', difficulty: 2),
    WordWithDifficulty('Moi Moche et Méchant', difficulty: 1),
    WordWithDifficulty("L'Âge de Glace", difficulty: 1),
    WordWithDifficulty('Le Chat Potté', difficulty: 1),
    WordWithDifficulty('Les Trolls', difficulty: 1),
    WordWithDifficulty('Rio', difficulty: 1),

    // ANIMATION NON-DISNEY - Moyen
    WordWithDifficulty('Dragons', difficulty: 2),
    WordWithDifficulty('Lego Movie', difficulty: 3),
    WordWithDifficulty('Les Croods', difficulty: 3),
    WordWithDifficulty('Boss Baby', difficulty: 3),
    WordWithDifficulty('Wallace et Gromit', difficulty: 3),
    WordWithDifficulty('Chicken Run', difficulty: 3),
    WordWithDifficulty('Tempête de boulettes géantes', difficulty: 3),

    // ANIMATION NON-DISNEY - Difficile
    WordWithDifficulty('Le Voyage de Chihiro', difficulty: 2),
    WordWithDifficulty('Mon Voisin Totoro', difficulty: 3),
    WordWithDifficulty('Princesse Mononoké', difficulty: 3),
    WordWithDifficulty('Le Château Ambulant', difficulty: 3),

    // SÉRIES - Facile
    WordWithDifficulty('Friends', difficulty: 1),
    WordWithDifficulty('Game of Thrones', difficulty: 1),
    WordWithDifficulty('Stranger Things', difficulty: 2),
    WordWithDifficulty('La Casa de Papel', difficulty: 2),
    WordWithDifficulty('The Walking Dead', difficulty: 2),
    WordWithDifficulty("Grey's Anatomy", difficulty: 1),
    WordWithDifficulty('How I Met Your Mother', difficulty: 2),
    WordWithDifficulty('The Big Bang Theory', difficulty: 2),
    WordWithDifficulty('Vikings', difficulty: 2),
    WordWithDifficulty('Lupin', difficulty: 2),

    // SÉRIES - Moyen
    WordWithDifficulty('Breaking Bad', difficulty: 2),
    WordWithDifficulty('Peaky Blinders', difficulty: 2),
    WordWithDifficulty('Narcos', difficulty: 2),
    WordWithDifficulty('Black Mirror', difficulty: 2),
    WordWithDifficulty('Sherlock', difficulty: 2),
    WordWithDifficulty('Squid Game', difficulty: 2),
    WordWithDifficulty('Wednesday', difficulty: 2),
    WordWithDifficulty('The Witcher', difficulty: 2),
    WordWithDifficulty('The Crown', difficulty: 2),
    WordWithDifficulty('Bridgerton', difficulty: 2),
    WordWithDifficulty('Emily in Paris', difficulty: 2),
    WordWithDifficulty('Succession', difficulty: 3),
    WordWithDifficulty('The Mandalorian', difficulty: 3),
    WordWithDifficulty('The Last of Us', difficulty: 2),
    WordWithDifficulty('Westworld', difficulty: 3),
    WordWithDifficulty('The Boys', difficulty: 2),

    // SÉRIES - Difficile
    WordWithDifficulty('The Office', difficulty: 3),
    WordWithDifficulty('Lost', difficulty: 3),
    WordWithDifficulty('Prison Break', difficulty: 3),
    WordWithDifficulty('Dexter', difficulty: 3),
    WordWithDifficulty('House', difficulty: 3),
    WordWithDifficulty('Better Call Saul', difficulty: 3),
    WordWithDifficulty('Ozark', difficulty: 3),
    WordWithDifficulty('True Detective', difficulty: 3),
    WordWithDifficulty('Fargo', difficulty: 3),
    WordWithDifficulty('The Wire', difficulty: 3),
    WordWithDifficulty('The Sopranos', difficulty: 3),
    WordWithDifficulty('Mad Men', difficulty: 3),
    WordWithDifficulty('Six Feet Under', difficulty: 3),
    WordWithDifficulty('Fleabag', difficulty: 3),

    // FILMS FRANÇAIS - Facile
    WordWithDifficulty('Intouchables', difficulty: 1),
    WordWithDifficulty('Taxi', difficulty: 1),
    WordWithDifficulty('Astérix et Obélix Mission Cléopâtre', difficulty: 1),
    WordWithDifficulty('Les Trois Frères', difficulty: 3),

    // FILMS FRANÇAIS - Moyen
    WordWithDifficulty('Amélie Poulain', difficulty: 2),
    WordWithDifficulty('Les Choristes', difficulty: 2),
    WordWithDifficulty("Le Fabuleux Destin d'Amélie Poulain", difficulty: 2),
    WordWithDifficulty('OSS 117', difficulty: 2),
    WordWithDifficulty("Qu'est-ce qu'on a fait au Bon Dieu", difficulty: 2),
    WordWithDifficulty('La Famille Bélier', difficulty: 2),
    WordWithDifficulty('Le Prénom', difficulty: 2),
    WordWithDifficulty('Les Tuche', difficulty: 2),

    // FILMS FRANÇAIS - Difficile
    WordWithDifficulty('La Haine', difficulty: 3),
    WordWithDifficulty('Le Dîner de Cons', difficulty: 3),
    WordWithDifficulty("Bienvenue chez les Ch'tis", difficulty: 3),
    WordWithDifficulty('Les Visiteurs', difficulty: 2),
    WordWithDifficulty('Le Grand Bleu', difficulty: 2),
    WordWithDifficulty('Léon', difficulty: 3),
    WordWithDifficulty('Nikita', difficulty: 3),
    WordWithDifficulty('La Boum', difficulty: 2),
    WordWithDifficulty('Les Bronzés', difficulty: 2),
    WordWithDifficulty('Le Père Noël est une ordure', difficulty: 3),

    // MANGA/ANIME - Facile
    WordWithDifficulty('Naruto', difficulty: 1),
    WordWithDifficulty('Dragon Ball', difficulty: 1),
    WordWithDifficulty('One Piece', difficulty: 1),
    WordWithDifficulty('Pokémon', difficulty: 1),
    WordWithDifficulty('Sailor Moon', difficulty: 3),
    WordWithDifficulty('Olive et Tom', difficulty: 1),
    WordWithDifficulty('Les Chevaliers du Zodiaque', difficulty: 3),

    // MANGA/ANIME - Moyen
    WordWithDifficulty("L'Attaque des Titans", difficulty: 2),
    WordWithDifficulty('Death Note', difficulty: 2),
    WordWithDifficulty('Demon Slayer', difficulty: 2),
    WordWithDifficulty('My Hero Academia', difficulty: 3),
    WordWithDifficulty('One Punch Man', difficulty: 3),
    WordWithDifficulty('Fairy Tail', difficulty: 3),
    WordWithDifficulty('Black Clover', difficulty: 3),
    WordWithDifficulty('Bleach', difficulty: 3),
    WordWithDifficulty('Fullmetal Alchemist', difficulty: 3),
    WordWithDifficulty('Sword Art Online', difficulty: 3),

    // MANGA/ANIME - Difficile
    WordWithDifficulty('Hunter x Hunter', difficulty: 2),
    WordWithDifficulty('Jujutsu Kaisen', difficulty: 3),
    WordWithDifficulty('Tokyo Ghoul', difficulty: 3),
    WordWithDifficulty('Vinland Saga', difficulty: 3),

    // PERSONNAGES DE FILMS/SÉRIES - Facile
    WordWithDifficulty('Mickey Mouse', difficulty: 1),
    WordWithDifficulty('Donald Duck', difficulty: 1),
    WordWithDifficulty('Elsa', difficulty: 3),
    WordWithDifficulty('Simba', difficulty: 1),
    WordWithDifficulty('Woody', difficulty: 2),
    WordWithDifficulty("Buzz l'Éclair", difficulty: 1),
    WordWithDifficulty('Olaf', difficulty: 2),
    WordWithDifficulty('Maui', difficulty: 3),
    WordWithDifficulty('Anna', difficulty: 2),
    WordWithDifficulty('Stitch', difficulty: 1),
    WordWithDifficulty('Flash McQueen', difficulty: 1),
    WordWithDifficulty('Martin', difficulty: 2),
    WordWithDifficulty('Rémy', difficulty: 2),
    WordWithDifficulty('Nala', difficulty: 1),

    // PERSONNAGES DE FILMS/SÉRIES - Moyen
    WordWithDifficulty('Dark Vador', difficulty: 1),
    WordWithDifficulty('Voldemort', difficulty: 1),
    WordWithDifficulty('Thanos', difficulty: 3),
    WordWithDifficulty('Sauron', difficulty: 2),
    WordWithDifficulty('Gandalf', difficulty: 2),
    WordWithDifficulty('Frodon', difficulty: 2),
    WordWithDifficulty('Hermione', difficulty: 2),
    WordWithDifficulty('Ron Weasley', difficulty: 2),
    WordWithDifficulty('Dumbledore', difficulty: 2),
    WordWithDifficulty('Severus Rogue', difficulty: 2),
    WordWithDifficulty('Jack Sparrow', difficulty: 2),
    WordWithDifficulty('Tony Stark', difficulty: 3),
    WordWithDifficulty('Peter Parker', difficulty: 3),
    WordWithDifficulty('Bruce Wayne', difficulty: 2),

    // PERSONNAGES DE FILMS/SÉRIES - Difficile
    WordWithDifficulty('Hannibal Lecter', difficulty: 3),
    WordWithDifficulty('Don Corleone', difficulty: 3),

    // DESSINS ANIMÉS TV - Facile
    WordWithDifficulty("Bob l'éponge", difficulty: 1),
    WordWithDifficulty('Les Simpson', difficulty: 1),
    WordWithDifficulty('Scooby-Doo', difficulty: 1),
    WordWithDifficulty('Tom et Jerry', difficulty: 1),
    WordWithDifficulty("Dora l'Exploratrice", difficulty: 1),
    WordWithDifficulty('Peppa Pig', difficulty: 3),
    WordWithDifficulty('Pat Patrouille', difficulty: 3),
    WordWithDifficulty('Les Télétubbies', difficulty: 1),

    // DESSINS ANIMÉS TV - Moyen
    WordWithDifficulty('Rick et Morty', difficulty: 2),
    WordWithDifficulty('South Park', difficulty: 2),
    WordWithDifficulty('Totally Spies', difficulty: 2),
    WordWithDifficulty('Code Lyoko', difficulty: 2),
    WordWithDifficulty("Avatar le dernier maître de l'air", difficulty: 3),

    // DESSINS ANIMÉS TV - Difficile
    WordWithDifficulty('Ben 10', difficulty: 3),
    WordWithDifficulty('Inspecteur Gadget', difficulty: 3),
    WordWithDifficulty('Il était une fois la vie', difficulty: 3),
    WordWithDifficulty("Il était une fois l'homme", difficulty: 3),
    WordWithDifficulty("Les Mystérieuses Cités d'Or", difficulty: 3),
    WordWithDifficulty('Wakfu', difficulty: 3),
    WordWithDifficulty('Oggy et les Cafards', difficulty: 3),
    WordWithDifficulty("Les zinzins de l'espace", difficulty: 3),

    // FILMS D'HORREUR - Facile
    WordWithDifficulty('Ça', difficulty: 1),
    WordWithDifficulty('Halloween', difficulty: 1),
    WordWithDifficulty('Scream', difficulty: 1),
    WordWithDifficulty('Saw', difficulty: 2),
    WordWithDifficulty('Annabelle', difficulty: 2),
    WordWithDifficulty('Chucky', difficulty: 1),
    WordWithDifficulty('Vendredi 13', difficulty: 1),
    WordWithDifficulty('The Ring', difficulty: 2),
    WordWithDifficulty('Conjuring', difficulty: 2),
    WordWithDifficulty('Insidious', difficulty: 2),

    // FILMS D'HORREUR - Moyen
    WordWithDifficulty("L'Exorciste", difficulty: 3),
    WordWithDifficulty('The Shining', difficulty: 2),
    WordWithDifficulty('Get Out', difficulty: 3),
    WordWithDifficulty('Us', difficulty: 3),
    WordWithDifficulty('A Quiet Place', difficulty: 3),
    WordWithDifficulty('Sinister', difficulty: 3),
    WordWithDifficulty('The Descent', difficulty: 3),
    WordWithDifficulty('Paranormal Activity', difficulty: 3),
    WordWithDifficulty('The Babadook', difficulty: 3),
    WordWithDifficulty('Midsommar', difficulty: 3),
    // COMÉDIES - Facile
    WordWithDifficulty('Very Bad Trip', difficulty: 2),
    WordWithDifficulty('Scary Movie', difficulty: 2),
    WordWithDifficulty('Maman j\'ai raté l\'avion', difficulty: 2),
    WordWithDifficulty('American Pie', difficulty: 2),

    // COMÉDIES - Moyen
    WordWithDifficulty('21 Jump Street', difficulty: 3),
    WordWithDifficulty('La Nuit au Musée', difficulty: 2),
    WordWithDifficulty('Dikkenek', difficulty: 2),
    WordWithDifficulty('Borat', difficulty: 2),

    // COMÉDIES - Difficile
    WordWithDifficulty('The Grand Budapest Hotel', difficulty: 3),

    // FILMS POLICIERS/THRILLERS - Facile
    WordWithDifficulty('Taken', difficulty: 1),
    WordWithDifficulty('Jason Bourne', difficulty: 2),
    WordWithDifficulty('Ocean\'s Eleven', difficulty: 2),
    WordWithDifficulty('Les Infiltrés', difficulty: 2),

    // FILMS POLICIERS/THRILLERS - Moyen
    WordWithDifficulty('Zodiac', difficulty: 2),
    WordWithDifficulty('Mystic River', difficulty: 3),
    WordWithDifficulty('Prisoners', difficulty: 2),
    WordWithDifficulty('L.A. Confidential', difficulty: 3),
    WordWithDifficulty('Heat', difficulty: 3),
    WordWithDifficulty('Usual Suspects', difficulty: 2),
    WordWithDifficulty('Memories of Murder', difficulty: 3),
    WordWithDifficulty('Le Fugitif', difficulty: 2),

    // WESTERNS - Facile
    WordWithDifficulty('Les Sept Mercenaires', difficulty: 2),
    WordWithDifficulty('Django', difficulty: 2),
    WordWithDifficulty('Il était une fois dans l\'Ouest', difficulty: 3),

    // WESTERNS - Moyen
    WordWithDifficulty('Le Bon, la Brute et le Truand', difficulty: 2),
    WordWithDifficulty('Impitoyable', difficulty: 3),

    // FILMS ROMANTIQUES - Facile
    WordWithDifficulty('The Notebook', difficulty: 3),
    WordWithDifficulty('Dirty Dancing', difficulty: 1),
    WordWithDifficulty('Ghost', difficulty: 1),
    WordWithDifficulty('Pretty Woman', difficulty: 1),
    WordWithDifficulty('Love Actually', difficulty: 2),
    WordWithDifficulty('Coup de foudre à notting Hill', difficulty: 2),
    WordWithDifficulty('Le Journal de Bridget Jones', difficulty: 2),

    // FILMS ROMANTIQUES - Moyen
    WordWithDifficulty('Nos étoiles contraires', difficulty: 2),
    WordWithDifficulty('Et si c\'était vrai', difficulty: 3),
    WordWithDifficulty('Crazy Stupid Love', difficulty: 2),
    WordWithDifficulty('Moulin Rouge', difficulty: 2),

    // FILMS ROMANTIQUES - Difficile
    WordWithDifficulty('Orgueil et Préjugés', difficulty: 2),
    WordWithDifficulty('Autant en emporte le vent', difficulty: 3),
    WordWithDifficulty('Casablanca', difficulty: 3),
    WordWithDifficulty('Les Parapluies de Cherbourg', difficulty: 3),

    // FILMS DE GUERRE - Facile
    WordWithDifficulty('Dunkerque', difficulty: 2),
    WordWithDifficulty('1917', difficulty: 2),
    WordWithDifficulty('Fury', difficulty: 3),
    WordWithDifficulty('Pearl Harbor', difficulty: 2),

    // FILMS DE GUERRE - Moyen
    WordWithDifficulty('Platoon', difficulty: 3),
    WordWithDifficulty('Full Metal Jacket', difficulty: 3),
    WordWithDifficulty('Black Hawk Down', difficulty: 2),
    WordWithDifficulty('Voyage au bout de l\'enfer', difficulty: 3),
    WordWithDifficulty('Troie', difficulty: 2),
    WordWithDifficulty('300', difficulty: 2),
    WordWithDifficulty('Joyeux Noël', difficulty: 2),

    // FILMS DE GUERRE - Difficile
    WordWithDifficulty('La Chute', difficulty: 3),

    // COMÉDIES MUSICALES - Facile
    WordWithDifficulty('Grease', difficulty: 2),
    WordWithDifficulty('Mamma Mia', difficulty: 2),
    WordWithDifficulty('High School Musical', difficulty: 1),
    WordWithDifficulty('Pitch Perfect', difficulty: 3),
    WordWithDifficulty('Le Roi et Moi', difficulty: 2),

    // COMÉDIES MUSICALES - Moyen
    WordWithDifficulty('Les Misérables', difficulty: 2),
    WordWithDifficulty('Chicago', difficulty: 2),
    WordWithDifficulty('West Side Story', difficulty: 2),
    WordWithDifficulty('The Greatest Showman', difficulty: 2),
    WordWithDifficulty('Hairspray', difficulty: 3),
    WordWithDifficulty('Singin\' in the Rain', difficulty: 3),

    // COMÉDIES MUSICALES - Difficile
    WordWithDifficulty('Cabaret', difficulty: 2),
    WordWithDifficulty('La Mélodie du Bonheur', difficulty: 3),
    WordWithDifficulty('Un Américain à Paris', difficulty: 3),
    WordWithDifficulty('Les Demoiselles de Rochefort', difficulty: 3),

    // FILMS DE SPORT - Facile
    WordWithDifficulty('Creed', difficulty: 3),
    WordWithDifficulty('Raging Bull', difficulty: 3),
    WordWithDifficulty('Million Dollar Baby', difficulty: 2),
    WordWithDifficulty('Rush', difficulty: 3),
    WordWithDifficulty('Cool Runnings', difficulty: 3),

    // FILMS DE SPORT - Moyen
    WordWithDifficulty('Invictus', difficulty: 2),
    WordWithDifficulty('Le Stratège', difficulty: 2),
    WordWithDifficulty('Le Pacte des Loups', difficulty: 3),
    WordWithDifficulty('Warrior', difficulty: 3),
    WordWithDifficulty('Les Chariots de Feu', difficulty: 3),

    // BIOPICS - Facile
    WordWithDifficulty('Bohemian Rhapsody', difficulty: 1),
    WordWithDifficulty('The Social Network', difficulty: 2),
    WordWithDifficulty('A Beautiful Mind', difficulty: 3),
    WordWithDifficulty('127 heures', difficulty: 3),
    WordWithDifficulty('The Imitation Game', difficulty: 2),

    // BIOPICS - Moyen
    WordWithDifficulty('Rocketman', difficulty: 2),
    WordWithDifficulty('Ray', difficulty: 2),
    WordWithDifficulty('La Môme', difficulty: 2),
    WordWithDifficulty('Jobs', difficulty: 2),
    WordWithDifficulty('The King\'s Speech', difficulty: 3),
    WordWithDifficulty('12 Years a Slave', difficulty: 3),

    // BIOPICS - Difficile
    WordWithDifficulty('Gandhi', difficulty: 2),
    WordWithDifficulty('Malcolm X', difficulty: 3),
    WordWithDifficulty('Amadeus', difficulty: 2),
    WordWithDifficulty('Patton', difficulty: 3),
    WordWithDifficulty('Lawrence d\'Arabie', difficulty: 3),

    // FRANCHISES/SAGAS - Facile
    WordWithDifficulty('Fast & Furious', difficulty: 1),
    WordWithDifficulty('Marvel', difficulty: 2),
    WordWithDifficulty('Star Trek', difficulty: 2),
    WordWithDifficulty('Bourne', difficulty: 2),
    WordWithDifficulty('Men in Black', difficulty: 2),

    // FRANCHISES/SAGAS - Moyen
    WordWithDifficulty('La Planète des Singes', difficulty: 2),
    WordWithDifficulty('Predator', difficulty: 3),
    WordWithDifficulty('RoboCop', difficulty: 3),
    WordWithDifficulty('Rambo', difficulty: 3),
    WordWithDifficulty('Die Hard', difficulty: 3),
    WordWithDifficulty('Expendables', difficulty: 3),
    WordWithDifficulty('John Wick', difficulty: 3),

    // FRANCHISES/SAGAS - Difficile
    WordWithDifficulty('Dune', difficulty: 3),
    WordWithDifficulty('Dollars Trilogy', difficulty: 3),
    WordWithDifficulty('Evil Dead', difficulty: 3),
    WordWithDifficulty('Before Trilogy', difficulty: 3),

    // FILMS DE NOËL - Facile
    WordWithDifficulty('Le Grinch', difficulty: 2),
    WordWithDifficulty('Maman j\'ai encore raté l\'avion', difficulty: 3),
    WordWithDifficulty('Le Pôle Express', difficulty: 2),
    WordWithDifficulty('L\'Étrange Noël de Mr Jack', difficulty: 2),

    // FILMS DE NOËL - Moyen
    WordWithDifficulty('Elf', difficulty: 3),
    WordWithDifficulty('Klaus', difficulty: 2),

    // FILMS DE NOËL - Difficile
    WordWithDifficulty('Edward aux mains d\'argent', difficulty: 2),
    WordWithDifficulty('La Vie est belle (It\'s a Wonderful Life)', difficulty: 3),
    WordWithDifficulty('Gremlins', difficulty: 3),
    WordWithDifficulty('Le Cauchemar avant Noël', difficulty: 3),
  ],
);
