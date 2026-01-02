import '../models.dart';

const categoryCelebrites = WordCategory(
  id: 'celebrites',
  name: 'Célébrités',
  icon: '⭐',
  words: [

      // SPORTIFS FOOTBALL - Facile
      WordWithDifficulty('Messi', difficulty: 1),
      WordWithDifficulty('Ronaldo', difficulty: 1),
      WordWithDifficulty('Mbappé', difficulty: 1),
      WordWithDifficulty('Neymar', difficulty: 1),
      WordWithDifficulty('Griezmann', difficulty: 1),

      // SPORTIFS FOOTBALL - Moyen
      WordWithDifficulty('Zinedine Zidane', difficulty: 1),
      WordWithDifficulty('Pelé', difficulty: 3),
      WordWithDifficulty('Maradona', difficulty: 2),
      WordWithDifficulty('Thierry Henry', difficulty: 2),
      WordWithDifficulty('Benzema', difficulty: 1),
      WordWithDifficulty('Giroud', difficulty: 2),
      WordWithDifficulty('Pogba', difficulty: 2),
      WordWithDifficulty('Kanté', difficulty: 2),

      // SPORTIFS FOOTBALL - Difficile
      WordWithDifficulty('Platini', difficulty: 3),
      WordWithDifficulty('Beckham', difficulty: 1),
      WordWithDifficulty('Iniesta', difficulty: 3),
      WordWithDifficulty('Xavi', difficulty: 3),

      // SPORTIFS AUTRES - Facile
      WordWithDifficulty('Nadal', difficulty: 1),
      WordWithDifficulty('Federer', difficulty: 1),
      WordWithDifficulty('Michael Jordan', difficulty: 1),
      WordWithDifficulty('Usain Bolt', difficulty: 1),

      // SPORTIFS AUTRES - Moyen
      WordWithDifficulty('Djokovic', difficulty: 1),
      WordWithDifficulty('Serena Williams', difficulty: 1),
      WordWithDifficulty('Tiger Woods', difficulty: 1),
      WordWithDifficulty('LeBron James', difficulty: 2),
      WordWithDifficulty('Mohammed Ali', difficulty: 2),
      WordWithDifficulty('Michael Phelps', difficulty: 2),
      WordWithDifficulty('Tony Parker', difficulty: 2),

      // SPORTIFS AUTRES - Difficile
      WordWithDifficulty('Kobe Bryant', difficulty: 3),
      WordWithDifficulty('Mike Tyson', difficulty: 2),
      WordWithDifficulty('Simone Biles', difficulty: 2),
      WordWithDifficulty('Lewis Hamilton', difficulty: 2),
      WordWithDifficulty('Michael Schumacher', difficulty: 2),
      WordWithDifficulty('Ayrton Senna', difficulty: 3),

      // CHANTEURS INTERNATIONAUX - Facile
      WordWithDifficulty('Beyoncé', difficulty: 1),
      WordWithDifficulty('Rihanna', difficulty: 1),
      WordWithDifficulty('Taylor Swift', difficulty: 1),
      WordWithDifficulty('Ed Sheeran', difficulty: 2),
      WordWithDifficulty('Adele', difficulty: 1),
      WordWithDifficulty('Justin Bieber', difficulty: 1),
      WordWithDifficulty('Shakira', difficulty: 1),

      // CHANTEURS INTERNATIONAUX - Moyen
      WordWithDifficulty('Elvis Presley', difficulty: 2),
      WordWithDifficulty('Michael Jackson', difficulty: 2),
      WordWithDifficulty('Madonna', difficulty: 2),
      WordWithDifficulty('Prince', difficulty: 3),
      WordWithDifficulty('David Bowie', difficulty: 3),
      WordWithDifficulty('Freddie Mercury', difficulty: 2),
      WordWithDifficulty('Bob Marley', difficulty: 2),
      WordWithDifficulty('Lady Gaga', difficulty: 2),
      WordWithDifficulty('Ariana Grande', difficulty: 2),
      WordWithDifficulty('Eminem', difficulty: 4),
      WordWithDifficulty('Drake', difficulty: 2),
      WordWithDifficulty('The Weeknd', difficulty: 2),
      WordWithDifficulty('Bruno Mars', difficulty: 2),
      WordWithDifficulty('Katy Perry', difficulty: 2),

      // CHANTEURS INTERNATIONAUX - Difficile
      WordWithDifficulty('John Lennon', difficulty: 3),
      WordWithDifficulty('Kanye West', difficulty: 3),
      WordWithDifficulty('Amy Winehouse', difficulty: 2),
      WordWithDifficulty('Whitney Houston', difficulty: 3),
      WordWithDifficulty('Frank Sinatra', difficulty: 3),

      // CHANTEURS FRANÇAIS - Facile
      WordWithDifficulty('Céline Dion', difficulty: 1),
      WordWithDifficulty('Johnny Hallyday', difficulty: 1),
      WordWithDifficulty('Stromae', difficulty: 2),

      // CHANTEURS FRANÇAIS - Moyen
      WordWithDifficulty('Renaud', difficulty: 2),
      WordWithDifficulty('Jacques Brel', difficulty: 3),
      WordWithDifficulty('Serge Gainsbourg', difficulty: 3),
      WordWithDifficulty('Charles Aznavour', difficulty: 2),
      WordWithDifficulty('Claude François', difficulty: 2),
      WordWithDifficulty('Michel Sardou', difficulty: 2),
      WordWithDifficulty('Jean-Jacques Goldman', difficulty: 2),

      // CHANTEURS FRANÇAIS - Difficile
      WordWithDifficulty('Édith Piaf', difficulty: 2),
      WordWithDifficulty('Daft Punk', difficulty: 2),
      WordWithDifficulty('Georges Brassens', difficulty: 3),
      WordWithDifficulty('Léo Ferré', difficulty: 3),
      WordWithDifficulty('Barbara', difficulty: 3),

      // ACTEURS HOLLYWOOD - Facile
      WordWithDifficulty('Leonardo DiCaprio', difficulty: 1),
      WordWithDifficulty('Brad Pitt', difficulty: 1),
      WordWithDifficulty('Tom Cruise', difficulty: 1),
      WordWithDifficulty('Will Smith', difficulty: 1),
      WordWithDifficulty('Johnny Depp', difficulty: 1),
      WordWithDifficulty('Dwayne Johnson', difficulty: 3),

      // ACTEURS HOLLYWOOD - Moyen
      WordWithDifficulty('Marilyn Monroe', difficulty: 2),
      WordWithDifficulty('Charlie Chaplin', difficulty: 2),
      WordWithDifficulty('Tom Hanks', difficulty: 2),
      WordWithDifficulty('Robert De Niro', difficulty: 2),
      WordWithDifficulty('Al Pacino', difficulty: 3),
      WordWithDifficulty('Morgan Freeman', difficulty: 2),
      WordWithDifficulty('Denzel Washington', difficulty: 2),
      WordWithDifficulty('Meryl Streep', difficulty: 2),
      WordWithDifficulty('Scarlett Johansson', difficulty: 2),
      WordWithDifficulty('Jennifer Lawrence', difficulty: 2),
      WordWithDifficulty('Angelina Jolie', difficulty: 2),
      WordWithDifficulty('Emma Watson', difficulty: 2),
      WordWithDifficulty('George Clooney', difficulty: 2),
      WordWithDifficulty('Matt Damon', difficulty: 2),

      // ACTEURS HOLLYWOOD - Difficile
      WordWithDifficulty('Audrey Hepburn', difficulty: 3),
      WordWithDifficulty('James Dean', difficulty: 3),
      WordWithDifficulty('Marlon Brando', difficulty: 3),
      WordWithDifficulty('Ryan Gosling', difficulty: 3),
      WordWithDifficulty('Cate Blanchett', difficulty: 3),
      WordWithDifficulty('Kate Winslet', difficulty: 3),
      WordWithDifficulty('Margot Robbie', difficulty: 3),

      // ACTEURS FRANÇAIS - Moyen
      WordWithDifficulty('Jean Dujardin', difficulty: 2),
      WordWithDifficulty('Omar Sy', difficulty: 2),
      WordWithDifficulty('Marion Cotillard', difficulty: 2),
      WordWithDifficulty('Louis de Funès', difficulty: 2),
      WordWithDifficulty('Fernandel', difficulty: 3),
      WordWithDifficulty('Sophie Marceau', difficulty: 2),

      // ACTEURS FRANÇAIS - Difficile
      WordWithDifficulty('Alain Delon', difficulty: 3),
      WordWithDifficulty('Jean-Paul Belmondo', difficulty: 3),
      WordWithDifficulty('Brigitte Bardot', difficulty: 3),
      WordWithDifficulty('Catherine Deneuve', difficulty: 3),
      WordWithDifficulty('Isabelle Adjani', difficulty: 3),

      // TÉLÉ-RÉALITÉ / INFLUENCEURS - Facile
      WordWithDifficulty('Kim Kardashian', difficulty: 1),
      WordWithDifficulty('Kylie Jenner', difficulty: 2),

      // TÉLÉ-RÉALITÉ / INFLUENCEURS - Moyen
      WordWithDifficulty('Nabilla', difficulty: 2),
      WordWithDifficulty('Les Marseillais', difficulty: 2),
      WordWithDifficulty('Kev Adams', difficulty: 2),

      // TÉLÉ-RÉALITÉ / INFLUENCEURS - Difficile
      WordWithDifficulty('Squeezie', difficulty: 2),
      WordWithDifficulty('McFly et Carlito', difficulty: 3),
      WordWithDifficulty('Inès Reg', difficulty: 3),

      // HUMORISTES - Facile
      WordWithDifficulty('Gad Elmaleh', difficulty: 1),
      WordWithDifficulty('Jamel Debbouze', difficulty: 1),

      // HUMORISTES - Moyen
      WordWithDifficulty('Florence Foresti', difficulty: 2),
      WordWithDifficulty('Laurent Gerra', difficulty: 2),
      WordWithDifficulty('Anne Roumanoff', difficulty: 2),
      WordWithDifficulty('Franck Dubosc', difficulty: 2),

      // HUMORISTES - Difficile
      WordWithDifficulty('Coluche', difficulty: 3),
      WordWithDifficulty('Roman Frayssinet', difficulty: 3),
      WordWithDifficulty('Raymond Devos', difficulty: 3),

      // ÉCRIVAINS - Facile
      WordWithDifficulty('Victor Hugo', difficulty: 1),
      WordWithDifficulty('Jules Verne', difficulty: 2),
      WordWithDifficulty('J.K. Rowling', difficulty: 2),

      // ÉCRIVAINS - Moyen
      WordWithDifficulty('Molière', difficulty: 2),
      WordWithDifficulty('Alexandre Dumas', difficulty: 2),
      WordWithDifficulty('Émile Zola', difficulty: 2),
      WordWithDifficulty('Gustave Flaubert', difficulty: 3),
      WordWithDifficulty('Guy de Maupassant', difficulty: 3),
      WordWithDifficulty('Albert Camus', difficulty: 3),
      WordWithDifficulty('Shakespeare', difficulty: 2),
      WordWithDifficulty('Tolkien', difficulty: 3),

      // ÉCRIVAINS - Difficile
      WordWithDifficulty('Honoré de Balzac', difficulty: 3),
      WordWithDifficulty('Marcel Proust', difficulty: 3),
      WordWithDifficulty('Jean-Paul Sartre', difficulty: 3),
      WordWithDifficulty('Simone de Beauvoir', difficulty: 3),
      WordWithDifficulty('Baudelaire', difficulty: 3),
      WordWithDifficulty('Rimbaud', difficulty: 3),
      WordWithDifficulty('Voltaire', difficulty: 3),
      WordWithDifficulty('Rousseau', difficulty: 3),
      WordWithDifficulty('Montesquieu', difficulty: 3),
      WordWithDifficulty('Hemingway', difficulty: 3),

      // PHILOSOPHES - Difficile
      WordWithDifficulty('Platon', difficulty: 3),
      WordWithDifficulty('Aristote', difficulty: 3),
      WordWithDifficulty('Socrate', difficulty: 3),
      WordWithDifficulty('Descartes', difficulty: 3),
      WordWithDifficulty('Nietzsche', difficulty: 3),

      // PERSONNAGES HISTORIQUES - Facile
      WordWithDifficulty('Napoléon', difficulty: 1),
      WordWithDifficulty('Jeanne d\'Arc', difficulty: 1),
      WordWithDifficulty('Louis XIV', difficulty: 1),

      // PERSONNAGES HISTORIQUES - Moyen
      WordWithDifficulty('Charlemagne', difficulty: 2),
      WordWithDifficulty('Vercingétorix', difficulty: 2),
      WordWithDifficulty('Louis XVI', difficulty: 2),
      WordWithDifficulty('Marie-Antoinette', difficulty: 2),
      WordWithDifficulty('Christophe Colomb', difficulty: 2),

      // PERSONNAGES HISTORIQUES - Difficile
      WordWithDifficulty('Jules César', difficulty: 3),
      WordWithDifficulty('Cléopâtre', difficulty: 3),
      WordWithDifficulty('Attila', difficulty: 3),
      WordWithDifficulty('François 1er', difficulty: 3),
      WordWithDifficulty('Henri IV', difficulty: 3),
      WordWithDifficulty('Robespierre', difficulty: 3),
      WordWithDifficulty('De Gaulle', difficulty: 2),
      WordWithDifficulty('Churchill', difficulty: 3),

      // LEADERS MONDIAUX - Moyen
      WordWithDifficulty('Gandhi', difficulty: 2),
      WordWithDifficulty('Nelson Mandela', difficulty: 2),
      WordWithDifficulty('Martin Luther King', difficulty: 2),

      // LEADERS MONDIAUX - Difficile
      WordWithDifficulty('Abraham Lincoln', difficulty: 3),
      WordWithDifficulty('John F. Kennedy', difficulty: 3),
      WordWithDifficulty('Mère Teresa', difficulty: 3),
      WordWithDifficulty('Dalai Lama', difficulty: 3),

      // POLITIQUES FRANÇAIS - Moyen
      WordWithDifficulty('Emmanuel Macron', difficulty: 1),
      WordWithDifficulty('François Hollande', difficulty: 1),

      // POLITIQUES FRANÇAIS - Difficile
      WordWithDifficulty('Jacques Chirac', difficulty: 2),
      WordWithDifficulty('François Mitterrand', difficulty: 3),
      WordWithDifficulty('Georges Pompidou', difficulty: 3),
      WordWithDifficulty('Valéry Giscard d\'Estaing', difficulty: 3),

      // SCIENTIFIQUES - Facile
      WordWithDifficulty('Einstein', difficulty: 1),
      WordWithDifficulty('Marie Curie', difficulty: 1),

      // SCIENTIFIQUES - Moyen
      WordWithDifficulty('Pasteur', difficulty: 2),
      WordWithDifficulty('Darwin', difficulty: 3),
      WordWithDifficulty('Newton', difficulty: 2),

      // SCIENTIFIQUES - Difficile
      WordWithDifficulty('Galilée', difficulty: 2),
      WordWithDifficulty('Tesla', difficulty: 2),
      WordWithDifficulty('Pythagore', difficulty: 2),
      WordWithDifficulty('Archimède', difficulty: 3),
      WordWithDifficulty('Léonard de Vinci', difficulty: 2),

      // TECH/BUSINESS - Facile
      WordWithDifficulty('Steve Jobs', difficulty: 1),
      WordWithDifficulty('Bill Gates', difficulty: 1),

      // TECH/BUSINESS - Moyen
      WordWithDifficulty('Mark Zuckerberg', difficulty: 2),

      // TECH/BUSINESS - Difficile
      WordWithDifficulty('Jeff Bezos', difficulty: 2),

      // RÉALISATEURS / CINÉASTES - Facile
      WordWithDifficulty('Steven Spielberg', difficulty: 1),
      WordWithDifficulty('Quentin Tarantino', difficulty: 1),
      WordWithDifficulty('Christopher Nolan', difficulty: 2),

      // RÉALISATEURS / CINÉASTES - Moyen
      WordWithDifficulty('Martin Scorsese', difficulty: 2),
      WordWithDifficulty('James Cameron', difficulty: 2),
      WordWithDifficulty('Tim Burton', difficulty: 3),
      WordWithDifficulty('Luc Besson', difficulty: 3),
      WordWithDifficulty('Ridley Scott', difficulty: 3),
      WordWithDifficulty('Denis Villeneuve', difficulty: 3),

      // RÉALISATEURS / CINÉASTES - Difficile
      WordWithDifficulty('Stanley Kubrick', difficulty: 3),
      WordWithDifficulty('Alfred Hitchcock', difficulty: 3),

      // ARTISTES PEINTRES / SCULPTEURS - Facile
      WordWithDifficulty('Pablo Picasso', difficulty: 2),
      WordWithDifficulty('Vincent Van Gogh', difficulty: 2),
      WordWithDifficulty('Claude Monet', difficulty: 3),

      // ARTISTES PEINTRES / SCULPTEURS - Moyen
      WordWithDifficulty('Salvador Dalí', difficulty: 2),
      WordWithDifficulty('Michel-Ange', difficulty: 2),
      WordWithDifficulty('Auguste Rodin', difficulty: 3),
      WordWithDifficulty('Rembrandt', difficulty: 3),
      WordWithDifficulty('Edgar Degas', difficulty: 3),
      WordWithDifficulty('Auguste Renoir', difficulty: 3),

      // ARTISTES PEINTRES / SCULPTEURS - Difficile
      WordWithDifficulty('Paul Cézanne', difficulty: 3),
      WordWithDifficulty('Édouard Manet', difficulty: 3),
      WordWithDifficulty('Henri Matisse', difficulty: 3),
      WordWithDifficulty('Vassily Kandinsky', difficulty: 3),
      WordWithDifficulty('Andy Warhol', difficulty: 2),
      WordWithDifficulty('Banksy', difficulty: 3),
      WordWithDifficulty('Frida Kahlo', difficulty: 3),

      // DESIGNERS / CRÉATEURS DE MODE - Facile
      WordWithDifficulty('Coco Chanel', difficulty: 2),
      WordWithDifficulty('Karl Lagerfeld', difficulty: 2),

      // DESIGNERS / CRÉATEURS DE MODE - Moyen
      WordWithDifficulty('Yves Saint Laurent', difficulty: 2),
      WordWithDifficulty('Christian Dior', difficulty: 2),
      WordWithDifficulty('Giorgio Armani', difficulty: 3),
      WordWithDifficulty('Gianni Versace', difficulty: 3),
      WordWithDifficulty('Jean-Paul Gaultier', difficulty: 2),

      // DESIGNERS / CRÉATEURS DE MODE - Difficile
      WordWithDifficulty('Pierre Cardin', difficulty: 3),

      // DJ / MUSIQUE ÉLECTRONIQUE - Facile
      WordWithDifficulty('David Guetta', difficulty: 1),
      WordWithDifficulty('Martin Garrix', difficulty: 2),

      // DJ / MUSIQUE ÉLECTRONIQUE - Moyen
      WordWithDifficulty('Calvin Harris', difficulty: 2),
      WordWithDifficulty('Avicii', difficulty: 2),
      WordWithDifficulty('DJ Snake', difficulty: 2),
      WordWithDifficulty('Skrillex', difficulty: 3),
      WordWithDifficulty('Tiësto', difficulty: 3),

      // DJ / MUSIQUE ÉLECTRONIQUE - Difficile
      WordWithDifficulty('Swedish House Mafia', difficulty: 2),
      WordWithDifficulty('Justice', difficulty: 2),

      // RAPPEURS FRANÇAIS - Facile
      WordWithDifficulty('Booba', difficulty: 2),
      WordWithDifficulty('Orelsan', difficulty: 1),

      // RAPPEURS FRANÇAIS - Moyen
      WordWithDifficulty('PNL', difficulty: 2),
      WordWithDifficulty('Nekfeu', difficulty: 1),
      WordWithDifficulty('Ninho', difficulty: 2),
      WordWithDifficulty('Soprano', difficulty: 2),
      WordWithDifficulty('Maître Gims', difficulty: 1),
      WordWithDifficulty('Jul', difficulty: 1),

      // RAPPEURS FRANÇAIS - Difficile
      WordWithDifficulty('IAM', difficulty: 3),
      WordWithDifficulty('NTM', difficulty: 3),
      WordWithDifficulty('MC Solaar', difficulty: 3),
      WordWithDifficulty('Oxmo Puccino', difficulty: 3),

      // GROUPES DE ROCK/POP - Facile
      WordWithDifficulty('The Beatles', difficulty: 2),
      WordWithDifficulty('Queen', difficulty: 2),
      WordWithDifficulty('Coldplay', difficulty: 2),

      // GROUPES DE ROCK/POP - Moyen
      WordWithDifficulty('The Rolling Stones', difficulty: 2),
      WordWithDifficulty('Led Zeppelin', difficulty: 3),
      WordWithDifficulty('Pink Floyd', difficulty: 3),
      WordWithDifficulty('U2', difficulty: 2),
      WordWithDifficulty('Nirvana', difficulty: 2),
      WordWithDifficulty('AC/DC', difficulty: 2),
      WordWithDifficulty('Metallica', difficulty: 3),
      WordWithDifficulty('Red Hot Chili Peppers', difficulty: 2),
      WordWithDifficulty('Radiohead', difficulty: 3),

      // GROUPES DE ROCK/POP - Difficile
      WordWithDifficulty('The Doors', difficulty: 3),
      WordWithDifficulty('The Who', difficulty: 3),
      WordWithDifficulty('Genesis', difficulty: 3),
      WordWithDifficulty('Téléphone', difficulty: 2),
      WordWithDifficulty('Indochine', difficulty: 2),

      // ANIMATEURS TV - Facile
      WordWithDifficulty('Nagui', difficulty: 2),

      // ANIMATEURS TV - Moyen
      WordWithDifficulty('Michel Drucker', difficulty: 2),
      WordWithDifficulty('Laurent Ruquier', difficulty: 3),
      WordWithDifficulty('Christophe Dechavanne', difficulty: 2),
      WordWithDifficulty('Julien Lepers', difficulty: 2),
      WordWithDifficulty('Nikos Aliagas', difficulty: 2),

      // ANIMATEURS TV - Difficile
      WordWithDifficulty('Michel Denisot', difficulty: 3),
      WordWithDifficulty('Guy Lux', difficulty: 3),

      // JOURNALISTES / PRÉSENTATEURS - Moyen
      WordWithDifficulty('Laurent Delahousse', difficulty: 2),
      WordWithDifficulty('David Pujadas', difficulty: 2),
      WordWithDifficulty('Anne-Sophie Lapix', difficulty: 2),
      WordWithDifficulty('Élise Lucet', difficulty: 2),

      // JOURNALISTES / PRÉSENTATEURS - Difficile
      WordWithDifficulty('Claire Chazal', difficulty: 2),

      // STREAMERS / YOUTUBEURS GAMING - Facile
      WordWithDifficulty('Gotaga', difficulty: 3),

      // STREAMERS / YOUTUBEURS GAMING - Moyen
      WordWithDifficulty('Kameto', difficulty: 3),
      WordWithDifficulty('Locklear', difficulty: 3),
      WordWithDifficulty('Domingo', difficulty: 3),
      WordWithDifficulty('Sardoche', difficulty: 3),

      // STREAMERS / YOUTUBEURS GAMING - Difficile
      WordWithDifficulty('Joueur du Grenier', difficulty: 3),

      // MAGICIENS / ILLUSIONNISTES - Facile
      WordWithDifficulty('David Copperfield', difficulty: 3),

      // MAGICIENS / ILLUSIONNISTES - Difficile
      WordWithDifficulty('Houdini', difficulty: 3),

      // CHEFS CUISINIERS - Facile
      WordWithDifficulty('Gordon Ramsay', difficulty: 2),
      WordWithDifficulty('Jamie Oliver', difficulty: 2),

      // CHEFS CUISINIERS - Moyen
      WordWithDifficulty('Cyril Lignac', difficulty: 2),
      WordWithDifficulty('Philippe Etchebest', difficulty: 2),
      WordWithDifficulty('Alain Ducasse', difficulty: 2),
      WordWithDifficulty('Pierre Hermé', difficulty: 2),
      WordWithDifficulty('Thierry Marx', difficulty: 2),

      // CHEFS CUISINIERS - Difficile
      WordWithDifficulty('Paul Bocuse', difficulty: 3),
      WordWithDifficulty('Joël Robuchon', difficulty: 3),

      // ASTRONAUTES - Facile
      WordWithDifficulty('Neil Armstrong', difficulty: 2),
      WordWithDifficulty('Thomas Pesquet', difficulty: 2),

      // ASTRONAUTES - Moyen
      WordWithDifficulty('Youri Gagarine', difficulty: 3),


      // AVENTURIERS / EXPLORATEURS - Facile
      WordWithDifficulty('Jacques Cousteau', difficulty: 2),

      // AVENTURIERS / EXPLORATEURS - Moyen
      WordWithDifficulty('Mike Horn', difficulty: 2),

      // AVENTURIERS / EXPLORATEURS - Difficile
      WordWithDifficulty('Magellan', difficulty: 2),
      WordWithDifficulty('Vasco de Gama', difficulty: 3),
      WordWithDifficulty('Marco Polo', difficulty: 2),

      // MANNEQUINS / TOP MODELS - Facile
      WordWithDifficulty('Naomi Campbell', difficulty: 3),
      WordWithDifficulty('Kate Moss', difficulty: 2),

      // MANNEQUINS / TOP MODELS - Moyen
      WordWithDifficulty('Gisele Bündchen', difficulty: 3),
      WordWithDifficulty('Claudia Schiffer', difficulty: 2),
      WordWithDifficulty('Cindy Crawford', difficulty: 3),
      WordWithDifficulty('Cara Delevingne', difficulty: 2),

      // MANNEQUINS / TOP MODELS - Difficile
      WordWithDifficulty('Laetitia Casta', difficulty: 3),

      // ACTIVISTES / MILITANTS - Facile
      WordWithDifficulty('Malala Yousafzai', difficulty: 3),
      WordWithDifficulty('Greta Thunberg', difficulty: 2),

      // ACTIVISTES / MILITANTS - Moyen
      WordWithDifficulty('Rosa Parks', difficulty: 2),
      WordWithDifficulty('Simone Veil', difficulty: 2),

      // ACTIVISTES / MILITANTS - Difficile
      WordWithDifficulty('Emmeline Pankhurst', difficulty: 3),
      WordWithDifficulty('Che Guevara', difficulty: 2),
      WordWithDifficulty('Malcolm X', difficulty: 3),

      // PERSONNALITÉS RELIGIEUSES - Moyen
      WordWithDifficulty('Le Pape François', difficulty: 2),
      WordWithDifficulty('Sœur Emmanuelle', difficulty: 2),

      // PERSONNALITÉS RELIGIEUSES - Difficile
      WordWithDifficulty('Jean-Paul II', difficulty: 3),
      WordWithDifficulty('Benoît XVI', difficulty: 3),

  ],
);
