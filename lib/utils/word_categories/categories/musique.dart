// ============================================================
// CATÉGORIE : Musique
// ============================================================
//
// DESCRIPTION :
// Univers musical : chansons célèbres, artistes, genres
// musicaux et termes liés à la musique.
//
// SECTIONS EXISTANTES :
// - Chansons françaises classiques (La vie en rose, La bohème)
// - Chansons françaises récentes (Dernière danse, Balance ton quoi)
// - Chansons internationales (Thriller, Bohemian Rhapsody)
// - Artistes français (Édith Piaf, Johnny Hallyday, Stromae)
// - Artistes internationaux (Michael Jackson, Beatles, Queen)
// - Genres musicaux (Rock, Rap, Jazz, Électro)
//
// IDÉES D'ENRICHISSEMENT :
// - Hits récents 2023-2025
// - Rappeurs français actuels
// - Artistes K-pop populaires
// - Festivals de musique (Solidays, Vieilles Charrues)
// - Groupes de rock légendaires
// - Artistes de variété française
// - Musiques de films célèbres
//
// CRITÈRES DE DIFFICULTÉ :
// - 1 (Facile) : Tubes universels (Thriller, La vie en rose)
// - 2 (Moyen) : Connu des mélomanes (Bohemian Rhapsody)
// - 3 (Difficile) : Niche ou ancien (Gainsbourg, morceaux obscurs)
//
// ============================================================

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
      WordWithDifficulty('Hotel California', difficulty: 3),
      WordWithDifficulty('Smells Like Teen Spirit', difficulty: 3),
      WordWithDifficulty('Billie Jean', difficulty: 2),
      WordWithDifficulty('Thriller', difficulty: 2),
      WordWithDifficulty('Beat It', difficulty: 2),
      WordWithDifficulty('Wonderwall', difficulty: 2),
      WordWithDifficulty('Lose Yourself', difficulty: 2),

      // CHANSONS INTERNATIONALES - Difficile
      WordWithDifficulty('God Save the Queen', difficulty: 2),
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
      WordWithDifficulty('Folk', difficulty: 3),
      WordWithDifficulty('House', difficulty: 2),
      WordWithDifficulty('Techno', difficulty: 2),
      WordWithDifficulty('Trap', difficulty: 3),
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

      // COMPOSITEURS CLASSIQUES - Facile
      WordWithDifficulty('Mozart', difficulty: 1),
      WordWithDifficulty('Beethoven', difficulty: 1),
      WordWithDifficulty('Bach', difficulty: 1),
      WordWithDifficulty('Vivaldi', difficulty: 2),

      // COMPOSITEURS CLASSIQUES - Moyen
      WordWithDifficulty('Chopin', difficulty: 3),
      WordWithDifficulty('Tchaïkovski', difficulty: 3),
      WordWithDifficulty('Debussy', difficulty: 3),
      WordWithDifficulty('Wagner', difficulty: 3),
      WordWithDifficulty('Schubert', difficulty: 3),

      // COMPOSITEURS CLASSIQUES - Difficile
      WordWithDifficulty('Ravel', difficulty: 3),
      WordWithDifficulty('Rachmaninov', difficulty: 3),
      WordWithDifficulty('Stravinsky', difficulty: 3),

      // FESTIVALS DE MUSIQUE - Facile
      WordWithDifficulty('Coachella', difficulty: 2),
      WordWithDifficulty('Tomorrowland', difficulty: 2),
      WordWithDifficulty('Les Vieilles Charrues', difficulty: 3),

      // FESTIVALS DE MUSIQUE - Moyen
      WordWithDifficulty('Hellfest', difficulty: 2),
      WordWithDifficulty('Rock en Seine', difficulty: 2),
      WordWithDifficulty('Solidays', difficulty: 2),
      WordWithDifficulty('Lollapalooza', difficulty: 2),
      WordWithDifficulty('Main Square Festival', difficulty: 3),
      WordWithDifficulty('Garorock', difficulty: 3),

      // FESTIVALS DE MUSIQUE - Difficile
      WordWithDifficulty('Glastonbury', difficulty: 3),
      WordWithDifficulty('Montreux Jazz Festival', difficulty: 3),
      WordWithDifficulty('Les Francofolies', difficulty: 3),

      // COMÉDIES MUSICALES - Facile
      WordWithDifficulty('Le Roi Lion', difficulty: 2),
      WordWithDifficulty('Les Misérables', difficulty: 2),
      WordWithDifficulty('Mamma Mia', difficulty: 2),

      // COMÉDIES MUSICALES - Moyen
      WordWithDifficulty('Notre-Dame de Paris', difficulty: 2),
      WordWithDifficulty('Roméo et Juliette', difficulty: 2),
      WordWithDifficulty('Le Fantôme de l\'Opéra', difficulty: 3),
      WordWithDifficulty('Chicago', difficulty: 3),
      WordWithDifficulty('Cats', difficulty: 3),
      WordWithDifficulty('La La Land', difficulty: 2),
      WordWithDifficulty('West Side Story', difficulty: 3),

      // COMÉDIES MUSICALES - Difficile
      WordWithDifficulty('Hamilton', difficulty: 3),
      WordWithDifficulty('Les Demoiselles de Rochefort', difficulty: 3),
      WordWithDifficulty('Starmania', difficulty: 3),
      WordWithDifficulty('Mozart, l\'opéra rock', difficulty: 3),

      // ÉMISSIONS/CONCOURS MUSICAUX - Facile
      WordWithDifficulty('The Voice', difficulty: 1),
      WordWithDifficulty('Star Academy', difficulty: 1),
      WordWithDifficulty('Nouvelle Star', difficulty: 1),

      // ÉMISSIONS/CONCOURS MUSICAUX - Moyen
      WordWithDifficulty('Eurovision', difficulty: 2),
      WordWithDifficulty('La France a un incroyable talent', difficulty: 2),
      WordWithDifficulty('N\'oubliez pas les paroles', difficulty: 2),
      WordWithDifficulty('Taratata', difficulty: 2),

      // ÉMISSIONS/CONCOURS MUSICAUX - Difficile
      WordWithDifficulty('Victoires de la Musique', difficulty: 3),
      WordWithDifficulty('Les Enfoirés', difficulty: 3),

      // CHANSONS DE FILMS/DESSINS ANIMÉS - Facile
      WordWithDifficulty('Let It Go', difficulty: 2),
      WordWithDifficulty('Hakuna Matata', difficulty: 1),
      WordWithDifficulty('Je suis ton meilleur ami', difficulty: 2),
      WordWithDifficulty('L\'histoire de la vie', difficulty: 2),

      // CHANSONS DE FILMS/DESSINS ANIMÉS - Moyen
      WordWithDifficulty('My Heart Will Go On', difficulty: 2),
      WordWithDifficulty('Eye of the Tiger', difficulty: 2),
      WordWithDifficulty('Sous l\'océan', difficulty: 2),
      WordWithDifficulty('Ce rêve bleu', difficulty: 2),
      WordWithDifficulty('Libérée, délivrée', difficulty: 2),
      WordWithDifficulty('Skyfall', difficulty: 2),

      // CHANSONS DE FILMS/DESSINS ANIMÉS - Difficile
      WordWithDifficulty('Time of My Life', difficulty: 3),

      // RÉCOMPENSES MUSICALES - Facile
      WordWithDifficulty('Grammy Awards', difficulty: 3),
      WordWithDifficulty('NRJ Music Awards', difficulty: 3),

      // DANSES - Facile
      WordWithDifficulty('Valse', difficulty: 2),
      WordWithDifficulty('Tango', difficulty: 3),
      WordWithDifficulty('Ballet', difficulty: 2),
      WordWithDifficulty('Breakdance', difficulty: 2),

      // DANSES - Moyen
      WordWithDifficulty('Cha-cha', difficulty: 3),
      WordWithDifficulty('Paso doble', difficulty: 3),
      WordWithDifficulty('Swing', difficulty: 2),
      WordWithDifficulty('Rumba', difficulty: 2),
      WordWithDifficulty('Madison', difficulty: 3),
      WordWithDifficulty('Rock and roll', difficulty: 2),

      // DANSES - Difficile
      WordWithDifficulty('Vogue', difficulty: 3),
      WordWithDifficulty('Claquettes', difficulty: 2),

      // OPÉRAS - Facile
      WordWithDifficulty('Carmen', difficulty: 3),
      WordWithDifficulty('La Traviata', difficulty: 3),


  ],
);
