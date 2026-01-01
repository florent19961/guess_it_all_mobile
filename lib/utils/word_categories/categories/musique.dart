import '../models.dart';

const categoryMusique = WordCategory(
  id: 'musique',
  name: 'Musique',
  icon: '🎵',
  words: [

      // CHANSONS FRANÇAISES CLASSIQUES - Facile
      WordWithDifficulty('La vie en rose', difficulty: 1),
      WordWithDifficulty('Non, je ne regrette rien', difficulty: 1),
      WordWithDifficulty('Aux Champs-Élysées', difficulty: 1),
      WordWithDifficulty('Dernière danse', difficulty: 2),
      WordWithDifficulty('Andalouse', difficulty: 3),
      WordWithDifficulty('Tout oublier', difficulty: 3),
      WordWithDifficulty('Balance ton quoi', difficulty: 3),

      // CHANSONS FRANÇAISES - Moyen
      WordWithDifficulty('La bohème', difficulty: 2),
      WordWithDifficulty('Comme d\'habitude', difficulty: 2),
      WordWithDifficulty('Ne me quitte pas', difficulty: 2),
      WordWithDifficulty('L\'aventurier', difficulty: 2),
      WordWithDifficulty('Foule sentimentale', difficulty: 2),
      WordWithDifficulty('Savoir aimer', difficulty: 2),
      WordWithDifficulty('Je veux', difficulty: 2),
      WordWithDifficulty('Papaoutai', difficulty: 2),
      WordWithDifficulty('Formidable', difficulty: 2),
      WordWithDifficulty('Tous les mêmes', difficulty: 2),
      WordWithDifficulty('Djadja', difficulty: 2),
      WordWithDifficulty('Bande organisée', difficulty: 2),

      // CHANSONS FRANÇAISES - Difficile
      WordWithDifficulty('Amsterdam', difficulty: 3),
      WordWithDifficulty('Les copains d\'abord', difficulty: 3),
      WordWithDifficulty('L\'hymne à l\'amour', difficulty: 3),
      WordWithDifficulty('Les Champs-Élysées', difficulty: 3),
      WordWithDifficulty('Que je t\'aime', difficulty: 3),
      WordWithDifficulty('Maintenant', difficulty: 3),

      // CHANSONS INTERNATIONALES - Facile
      WordWithDifficulty('Shape of You', difficulty: 1),
      WordWithDifficulty('Despacito', difficulty: 1),
      WordWithDifficulty('Uptown Funk', difficulty: 1),
      WordWithDifficulty('Happy', difficulty: 1),
      WordWithDifficulty('Hello', difficulty: 1),
      WordWithDifficulty('Rolling in the Deep', difficulty: 1),
      WordWithDifficulty('Someone Like You', difficulty: 1),
      WordWithDifficulty('Blinding Lights', difficulty: 2),
      WordWithDifficulty('Levitating', difficulty: 2),
      WordWithDifficulty('Bad Guy', difficulty: 2),

      // CHANSONS INTERNATIONALES - Moyen
      WordWithDifficulty('Bohemian Rhapsody', difficulty: 2),
      WordWithDifficulty('Imagine', difficulty: 2),
      WordWithDifficulty('Let It Be', difficulty: 2),
      WordWithDifficulty('Hotel California', difficulty: 2),
      WordWithDifficulty('Smells Like Teen Spirit', difficulty: 2),
      WordWithDifficulty('Billie Jean', difficulty: 2),
      WordWithDifficulty('Thriller', difficulty: 2),
      WordWithDifficulty('Beat It', difficulty: 2),
      WordWithDifficulty('Wonderwall', difficulty: 2),
      WordWithDifficulty('Lose Yourself', difficulty: 2),

      // CHANSONS INTERNATIONALES - Difficile
      WordWithDifficulty('God Save the Queen', difficulty: 3),
      WordWithDifficulty('No Woman, No Cry', difficulty: 3),

      // GENRES MUSICAUX - Facile
      WordWithDifficulty('Pop', difficulty: 1),
      WordWithDifficulty('Rock', difficulty: 1),
      WordWithDifficulty('Rap', difficulty: 1),
      WordWithDifficulty('Jazz', difficulty: 1),
      WordWithDifficulty('Classique', difficulty: 1),
      WordWithDifficulty('Électro', difficulty: 1),
      WordWithDifficulty('Reggae', difficulty: 1),
      WordWithDifficulty('Country', difficulty: 1),

      // GENRES MUSICAUX - Moyen
      WordWithDifficulty('Hip-hop', difficulty: 2),
      WordWithDifficulty('Blues', difficulty: 2),
      WordWithDifficulty('Soul', difficulty: 2),
      WordWithDifficulty('Funk', difficulty: 2),
      WordWithDifficulty('R&B', difficulty: 2),
      WordWithDifficulty('Metal', difficulty: 2),
      WordWithDifficulty('Punk', difficulty: 2),
      WordWithDifficulty('Disco', difficulty: 2),
      WordWithDifficulty('Folk', difficulty: 2),
      WordWithDifficulty('House', difficulty: 2),
      WordWithDifficulty('Techno', difficulty: 2),
      WordWithDifficulty('Trap', difficulty: 2),
      WordWithDifficulty('Zouk', difficulty: 2),
      WordWithDifficulty('Salsa', difficulty: 2),

      // GENRES MUSICAUX - Difficile
      WordWithDifficulty('Dubstep', difficulty: 3),
      WordWithDifficulty('Drum and Bass', difficulty: 3),
      WordWithDifficulty('Hardstyle', difficulty: 3),
      WordWithDifficulty('Trance', difficulty: 3),
      WordWithDifficulty('Hardcore', difficulty: 3),
      WordWithDifficulty('Bossa Nova', difficulty: 3),
      WordWithDifficulty('Flamenco', difficulty: 3),
      WordWithDifficulty('Gospel', difficulty: 3),
      WordWithDifficulty('Indie Rock', difficulty: 3),
      WordWithDifficulty('Afrobeat', difficulty: 3),
      WordWithDifficulty('K-pop', difficulty: 3),
      WordWithDifficulty('Drill', difficulty: 3),

      // ARTISTES ET GROUPES - Facile
      WordWithDifficulty('Beatles', difficulty: 1),
      WordWithDifficulty('Queen', difficulty: 1),
      WordWithDifficulty('Michael Jackson', difficulty: 1),
      WordWithDifficulty('Madonna', difficulty: 1),
      WordWithDifficulty('Elvis Presley', difficulty: 1),
      WordWithDifficulty('Adele', difficulty: 1),
      WordWithDifficulty('Rihanna', difficulty: 1),
      WordWithDifficulty('Beyoncé', difficulty: 1),

      // ARTISTES ET GROUPES - Moyen
      WordWithDifficulty('Pink Floyd', difficulty: 2),
      WordWithDifficulty('Led Zeppelin', difficulty: 3),
      WordWithDifficulty('Rolling Stones', difficulty: 2),
      WordWithDifficulty('Nirvana', difficulty: 2),
      WordWithDifficulty('Radiohead', difficulty: 2),
      WordWithDifficulty('Coldplay', difficulty: 2),
      WordWithDifficulty('U2', difficulty: 2),
      WordWithDifficulty('Bob Marley', difficulty: 2),
      WordWithDifficulty('David Bowie', difficulty: 3),
      WordWithDifficulty('Prince', difficulty: 2),

      // TERMES MUSICAUX - Difficile
      WordWithDifficulty('Crescendo', difficulty: 3),
      WordWithDifficulty('Allegro', difficulty: 3),
      WordWithDifficulty('Fortissimo', difficulty: 3),
      WordWithDifficulty('Arpège', difficulty: 3),
    
  ],
);
