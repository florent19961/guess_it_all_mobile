import '../models.dart';

const categoryMarques = WordCategory(
  id: 'marques',
  name: 'Marques',
  icon: '🏷️',
  words: [

      // MARQUES DE VÊTEMENTS - Facile
      WordWithDifficulty('Nike', difficulty: 1),
      WordWithDifficulty('Adidas', difficulty: 1),
      WordWithDifficulty('Zara', difficulty: 1),
      WordWithDifficulty('H&M', difficulty: 1),
      WordWithDifficulty('Lacoste', difficulty: 1),
      WordWithDifficulty('Puma', difficulty: 1),
      WordWithDifficulty('Converse', difficulty: 1),
      WordWithDifficulty('Vans', difficulty: 1),

      // MARQUES DE VÊTEMENTS - Moyen
      WordWithDifficulty('Ralph Lauren', difficulty: 2),
      WordWithDifficulty('Tommy Hilfiger', difficulty: 2),
      WordWithDifficulty('Calvin Klein', difficulty: 2),
      WordWithDifficulty('Levi\'s', difficulty: 2),
      WordWithDifficulty('Diesel', difficulty: 2),
      WordWithDifficulty('Gap', difficulty: 2),
      WordWithDifficulty('Uniqlo', difficulty: 2),
      WordWithDifficulty('Mango', difficulty: 2),

      // MARQUES DE LUXE - Difficile
      WordWithDifficulty('Gucci', difficulty: 3),
      WordWithDifficulty('Prada', difficulty: 3),
      WordWithDifficulty('Chanel', difficulty: 3),
      WordWithDifficulty('Louis Vuitton', difficulty: 3),
      WordWithDifficulty('Hermès', difficulty: 3),
      WordWithDifficulty('Dior', difficulty: 3),
      WordWithDifficulty('Versace', difficulty: 3),
      WordWithDifficulty('Armani', difficulty: 3),
      WordWithDifficulty('Burberry', difficulty: 3),

      // MARQUES AUTOMOBILES - Facile
      WordWithDifficulty('Renault', difficulty: 1),
      WordWithDifficulty('Peugeot', difficulty: 1),
      WordWithDifficulty('Citroën', difficulty: 1),
      WordWithDifficulty('Volkswagen', difficulty: 1),
      WordWithDifficulty('Toyota', difficulty: 1),
      WordWithDifficulty('Ford', difficulty: 1),
      WordWithDifficulty('Mercedes', difficulty: 1),
      WordWithDifficulty('BMW', difficulty: 1),

      // MARQUES AUTOMOBILES - Moyen
      WordWithDifficulty('Audi', difficulty: 2),
      WordWithDifficulty('Nissan', difficulty: 2),
      WordWithDifficulty('Honda', difficulty: 3),
      WordWithDifficulty('Mazda', difficulty: 3),
      WordWithDifficulty('Hyundai', difficulty: 3),
      WordWithDifficulty('Kia', difficulty: 3),
      WordWithDifficulty('Fiat', difficulty: 2),
      WordWithDifficulty('Seat', difficulty: 2),
      WordWithDifficulty('Skoda', difficulty: 3),
      WordWithDifficulty('Opel', difficulty: 2),

      // MARQUES AUTOMOBILES LUXE - Difficile
      WordWithDifficulty('Ferrari', difficulty: 1),
      WordWithDifficulty('Lamborghini', difficulty: 2),
      WordWithDifficulty('Porsche', difficulty: 1),
      WordWithDifficulty('Maserati', difficulty: 3),
      WordWithDifficulty('Bugatti', difficulty: 3),
      WordWithDifficulty('Bentley', difficulty: 3),
      WordWithDifficulty('Rolls-Royce', difficulty: 3),
      WordWithDifficulty('Aston Martin', difficulty: 3),

      // MARQUES TECHNOLOGIE - Facile
      WordWithDifficulty('Apple', difficulty: 1),
      WordWithDifficulty('Samsung', difficulty: 1),
      WordWithDifficulty('Microsoft', difficulty: 1),
      WordWithDifficulty('Google', difficulty: 1),
      WordWithDifficulty('Sony', difficulty: 2),
      WordWithDifficulty('LG', difficulty: 2),
      WordWithDifficulty('HP', difficulty: 2),
      WordWithDifficulty('Dell', difficulty: 2),

      // MARQUES TECHNOLOGIE - Moyen
      WordWithDifficulty('Asus', difficulty: 3),
      WordWithDifficulty('Lenovo', difficulty: 3),
      WordWithDifficulty('Acer', difficulty: 3),
      WordWithDifficulty('Philips', difficulty: 2),
      WordWithDifficulty('Panasonic', difficulty: 3),
      WordWithDifficulty('Toshiba', difficulty: 3),
      WordWithDifficulty('Huawei', difficulty: 3),
      WordWithDifficulty('Xiaomi', difficulty: 3),

      // MARQUES ALIMENTATION - Facile
      WordWithDifficulty('Coca-Cola', difficulty: 1),
      WordWithDifficulty('Pepsi', difficulty: 1),
      WordWithDifficulty('Nutella', difficulty: 1),
      WordWithDifficulty('Kinder', difficulty: 1),
      WordWithDifficulty('Haribo', difficulty: 1),
      WordWithDifficulty('Nestlé', difficulty: 1),
      WordWithDifficulty('Danone', difficulty: 1),
      WordWithDifficulty('Lu', difficulty: 1),
      WordWithDifficulty('Fanta', difficulty: 1),
      WordWithDifficulty('Sprite', difficulty: 1),
      WordWithDifficulty('Orangina', difficulty: 1),
      WordWithDifficulty('Evian', difficulty: 1),
      WordWithDifficulty('Volvic', difficulty: 1),
      WordWithDifficulty('Perrier', difficulty: 1),
      WordWithDifficulty('Heinz', difficulty: 1),
      WordWithDifficulty('Président', difficulty: 1),
      WordWithDifficulty('Capri-Sun', difficulty: 2),
      WordWithDifficulty('Tropicana', difficulty: 1),
      WordWithDifficulty('Bonne Maman', difficulty: 1),
      WordWithDifficulty('Panzani', difficulty: 1),
      WordWithDifficulty('Barilla', difficulty: 1),
      WordWithDifficulty('Herta', difficulty: 1),
      WordWithDifficulty('Fleury Michon', difficulty: 1),
      WordWithDifficulty('Charal', difficulty: 1),
      WordWithDifficulty('Bonduelle', difficulty: 1),
      WordWithDifficulty('Yoplait', difficulty: 1),
      WordWithDifficulty('Activia', difficulty: 1),
      WordWithDifficulty('Kellogg\'s', difficulty: 1),
      WordWithDifficulty('Céréales Lion', difficulty: 1),

      // MARQUES ALIMENTATION - Moyen
      WordWithDifficulty('Mars', difficulty: 2),
      WordWithDifficulty('Snickers', difficulty: 2),
      WordWithDifficulty('Milka', difficulty: 2),
      WordWithDifficulty('Ferrero', difficulty: 2),
      WordWithDifficulty('Lindt', difficulty: 2),
      WordWithDifficulty('Pringles', difficulty: 2),
      WordWithDifficulty('Lay\'s', difficulty: 2),
      WordWithDifficulty('Oreo', difficulty: 2),
      WordWithDifficulty('KitKat', difficulty: 2),
      WordWithDifficulty('Ben & Jerry\'s', difficulty: 2),
      WordWithDifficulty('Twix', difficulty: 2),
      WordWithDifficulty('Bounty', difficulty: 2),
      WordWithDifficulty('M&M\'s', difficulty: 2),
      WordWithDifficulty('Skittles', difficulty: 2),
      WordWithDifficulty('Tic Tac', difficulty: 2),
      WordWithDifficulty('Mentos', difficulty: 2),
      WordWithDifficulty('Chupa Chups', difficulty: 2),
      WordWithDifficulty('Carambar', difficulty: 2),
      WordWithDifficulty('Malabar', difficulty: 2),
      WordWithDifficulty('Tagada', difficulty: 2),
      WordWithDifficulty('Dragibus', difficulty: 2),
      WordWithDifficulty('Red Bull', difficulty: 2),
      WordWithDifficulty('Monster Energy', difficulty: 2),
      WordWithDifficulty('Oasis', difficulty: 2),
      WordWithDifficulty('Schweppes', difficulty: 2),
      WordWithDifficulty('Lipton', difficulty: 2),
      WordWithDifficulty('Cristaline', difficulty: 2),
      WordWithDifficulty('Badoit', difficulty: 2),
      WordWithDifficulty('San Pellegrino', difficulty: 2),
      WordWithDifficulty('Contrex', difficulty: 2),
      WordWithDifficulty('Vittel', difficulty: 2),
      WordWithDifficulty('Amora', difficulty: 2),
      WordWithDifficulty('Maille', difficulty: 2),
      WordWithDifficulty('Kikkoman', difficulty: 3),
      WordWithDifficulty('Tabasco', difficulty: 2),
      WordWithDifficulty('Philadelphia', difficulty: 2),
      WordWithDifficulty('Babybel', difficulty: 2),
      WordWithDifficulty('La Vache qui rit', difficulty: 2),
      WordWithDifficulty('Kiri', difficulty: 2),
      WordWithDifficulty('Boursin', difficulty: 2),
      WordWithDifficulty('Caprice des Dieux', difficulty: 2),
      WordWithDifficulty('Saint Môret', difficulty: 2),
      WordWithDifficulty('Häagen-Dazs', difficulty: 2),
      WordWithDifficulty('Magnum', difficulty: 2),
      WordWithDifficulty('Carte d\'Or', difficulty: 2),
      WordWithDifficulty('Brossard', difficulty: 2),
      WordWithDifficulty('St Michel', difficulty: 2),
      WordWithDifficulty('Gerblé', difficulty: 2),
      WordWithDifficulty('Bjorg', difficulty: 3),
      WordWithDifficulty('Uncle Ben\'s', difficulty: 2),
      WordWithDifficulty('Ebly', difficulty: 3),
      WordWithDifficulty('Lustucru', difficulty: 2),
      WordWithDifficulty('Tipiak', difficulty: 2),
      WordWithDifficulty('Cassegrain', difficulty: 2),
      WordWithDifficulty('D\'aucy', difficulty: 2),
      WordWithDifficulty('Géant Vert', difficulty: 2),
      WordWithDifficulty('William Saurin', difficulty: 3),
      WordWithDifficulty('Côte d\'Or', difficulty: 2),
      WordWithDifficulty('Toblerone', difficulty: 2),
      WordWithDifficulty('Merci', difficulty: 2),
      WordWithDifficulty('Raffaello', difficulty: 2),
      WordWithDifficulty('Ferrero Rocher', difficulty: 2),
      WordWithDifficulty('Mon Chéri', difficulty: 2),
      WordWithDifficulty('Celebrations', difficulty: 2),

      // MARQUES ALIMENTATION - Difficile
      WordWithDifficulty('Poulain', difficulty: 3),
      WordWithDifficulty('Banania', difficulty: 3),
      WordWithDifficulty('Ricoré', difficulty: 3),
      WordWithDifficulty('Belvita', difficulty: 3),
      WordWithDifficulty('Grany', difficulty: 3),
      WordWithDifficulty('Pitch', difficulty: 3),
      WordWithDifficulty('Savane', difficulty: 3),
      WordWithDifficulty('Napolitain', difficulty: 3),
      WordWithDifficulty('Granola', difficulty: 3),
      WordWithDifficulty('Petit Écolier', difficulty: 2),
      WordWithDifficulty('Paille d\'Or', difficulty: 3),
      WordWithDifficulty('Petit Beurre', difficulty: 2),
      WordWithDifficulty('BN', difficulty: 2),
      WordWithDifficulty('Mikado', difficulty: 2),
      WordWithDifficulty('Pepito', difficulty: 2),
      WordWithDifficulty('Prince', difficulty: 2),
      WordWithDifficulty('Figolu', difficulty: 3),
      WordWithDifficulty('Finger', difficulty: 3),
      WordWithDifficulty('Pépito', difficulty: 3),
      WordWithDifficulty('Curly', difficulty: 3),
      WordWithDifficulty('Benenuts', difficulty: 3),
      WordWithDifficulty('Vico', difficulty: 3),
      WordWithDifficulty('Apéricube', difficulty: 3),
      WordWithDifficulty('Tuc', difficulty: 3),
      WordWithDifficulty('Cracotte', difficulty: 3),
      WordWithDifficulty('Krisprolls', difficulty: 3),

      // MARQUES FAST-FOOD - Facile
      WordWithDifficulty('McDonald\'s', difficulty: 1),
      WordWithDifficulty('Burger King', difficulty: 1),
      WordWithDifficulty('KFC', difficulty: 1),
      WordWithDifficulty('Quick', difficulty: 1),
      WordWithDifficulty('Subway', difficulty: 1),
      WordWithDifficulty('Domino\'s', difficulty: 1),
      WordWithDifficulty('Pizza Hut', difficulty: 1),
      WordWithDifficulty('Paul', difficulty: 2),
      WordWithDifficulty('Brioche Dorée', difficulty: 2),

      // MARQUES FAST-FOOD - Moyen
      WordWithDifficulty('Five Guys', difficulty: 3),
      WordWithDifficulty('Chipotle', difficulty: 3),
      WordWithDifficulty('Starbucks', difficulty: 2),
      WordWithDifficulty('Buffalo Grill', difficulty: 2),
      WordWithDifficulty('Hippopotamus', difficulty: 2),
      WordWithDifficulty('Courtepaille', difficulty: 2),
      WordWithDifficulty('Flunch', difficulty:2),
      WordWithDifficulty('Léon de Bruxelles', difficulty: 3),

      // MAGASINS - Facile
      WordWithDifficulty('Carrefour', difficulty: 1),
      WordWithDifficulty('Auchan', difficulty: 1),
      WordWithDifficulty('Leclerc', difficulty: 1),
      WordWithDifficulty('Lidl', difficulty: 1),
      WordWithDifficulty('Ikea', difficulty: 1),
      WordWithDifficulty('Fnac', difficulty: 1),
      WordWithDifficulty('Darty', difficulty: 1),
      WordWithDifficulty('Décathlon', difficulty: 1),

      // MAGASINS - Moyen
      WordWithDifficulty('Leroy Merlin', difficulty: 2),
      WordWithDifficulty('Castorama', difficulty: 2),
      WordWithDifficulty('Boulanger', difficulty: 2),
      WordWithDifficulty('Conforama', difficulty: 2),
      WordWithDifficulty('But', difficulty: 2),
      WordWithDifficulty('Monoprix', difficulty: 2),
      WordWithDifficulty('Franprix', difficulty: 2),
      WordWithDifficulty('Intermarché', difficulty: 2),

      // MARQUES BRICOLAGE - Moyen
      WordWithDifficulty('Bosch', difficulty: 2),
      WordWithDifficulty('Karcher', difficulty: 2),

      // MARQUES COSMÉTIQUES - Moyen
      WordWithDifficulty('L\'Oréal', difficulty: 2),
      WordWithDifficulty('Maybelline', difficulty: 2),
      WordWithDifficulty('Nivea', difficulty: 2),
      WordWithDifficulty('Garnier', difficulty: 2),
      WordWithDifficulty('Dove', difficulty: 2),
      WordWithDifficulty('Lancôme', difficulty: 2),

      // MARQUES SPORT - Moyen
      WordWithDifficulty('Reebok', difficulty: 2),
      WordWithDifficulty('New Balance', difficulty: 2),
      WordWithDifficulty('Asics', difficulty: 2),
      WordWithDifficulty('Under Armour', difficulty: 3),
      WordWithDifficulty('The North Face', difficulty: 2),
      WordWithDifficulty('Columbia', difficulty: 2),
      WordWithDifficulty('Quiksilver', difficulty: 2),

      // MARQUES JOUETS - Moyen
      WordWithDifficulty('Lego', difficulty: 2),
      WordWithDifficulty('Playmobil', difficulty: 2),
      WordWithDifficulty('Barbie', difficulty: 2),
      WordWithDifficulty('Hot Wheels', difficulty: 2),
      WordWithDifficulty('Nerf', difficulty: 2),

      // MARQUES D'ÉLECTROMÉNAGER - Facile
      WordWithDifficulty('Moulinex', difficulty: 3),
      WordWithDifficulty('SEB', difficulty: 3),
      WordWithDifficulty('Tefal', difficulty: 2),
      WordWithDifficulty('Dyson', difficulty: 2),
      WordWithDifficulty('Rowenta', difficulty: 3),

      // MARQUES D'ÉLECTROMÉNAGER - Moyen
      WordWithDifficulty('Whirlpool', difficulty: 3),
      WordWithDifficulty('Electrolux', difficulty: 3),
      WordWithDifficulty('Miele', difficulty: 3),
      WordWithDifficulty('Calor', difficulty: 3),
      WordWithDifficulty('DeLonghi', difficulty: 3),
      WordWithDifficulty('Brandt', difficulty: 2),
      WordWithDifficulty('Siemens', difficulty: 2),

      // MARQUES DE BANQUES/ASSURANCES - Facile
      WordWithDifficulty('BNP Paribas', difficulty: 2),
      WordWithDifficulty('Crédit Agricole', difficulty: 2),
      WordWithDifficulty('Société Générale', difficulty: 2),
      WordWithDifficulty('AXA', difficulty: 2),
      WordWithDifficulty('La Poste', difficulty: 2),

      // MARQUES DE BANQUES/ASSURANCES - Moyen
      WordWithDifficulty('MAIF', difficulty: 2),
      WordWithDifficulty('MAAF', difficulty: 2),
      WordWithDifficulty('Groupama', difficulty: 3),
      WordWithDifficulty('Caisse d\'Épargne', difficulty: 3),
      WordWithDifficulty('Banque Populaire', difficulty: 3),
      WordWithDifficulty('LCL', difficulty: 2),
      WordWithDifficulty('Crédit Mutuel', difficulty: 2),
      WordWithDifficulty('Macif', difficulty: 3),
      WordWithDifficulty('GMF', difficulty: 3),
      WordWithDifficulty('Direct Assurance', difficulty: 3),

      // MARQUES DE BANQUES/ASSURANCES - Difficile
      WordWithDifficulty('Boursorama', difficulty: 3),
      WordWithDifficulty('ING', difficulty: 3),
      WordWithDifficulty('Allianz', difficulty: 3),

      // MARQUES DE TÉLÉCOMS - Facile
      WordWithDifficulty('Orange', difficulty: 1),
      WordWithDifficulty('SFR', difficulty: 2),
      WordWithDifficulty('Bouygues Telecom', difficulty: 2),
      WordWithDifficulty('Free', difficulty: 2),

      // MARQUES DE TÉLÉCOMS - Moyen
      WordWithDifficulty('Red by SFR', difficulty: 3),
      WordWithDifficulty('Sosh', difficulty: 3),

      // MARQUES D'ALCOOL/SPIRITUEUX - Facile
      WordWithDifficulty('Heineken', difficulty: 3),
      WordWithDifficulty('Kronenbourg', difficulty: 2),
      WordWithDifficulty('1664', difficulty: 2),
      WordWithDifficulty('Desperados', difficulty: 2),
      WordWithDifficulty('Coca Cola', difficulty: 2),

      // MARQUES D'ALCOOL/SPIRITUEUX - Moyen
      WordWithDifficulty('Jack Daniel\'s', difficulty: 3),
      WordWithDifficulty('Absolut', difficulty: 3),
      WordWithDifficulty('Ricard', difficulty: 2),
      WordWithDifficulty('Pastis 51', difficulty: 3),
      WordWithDifficulty('Smirnoff', difficulty: 3),
      WordWithDifficulty('Bacardi', difficulty: 3),
      WordWithDifficulty('Malibu', difficulty: 3),
      WordWithDifficulty('Martini', difficulty: 3),
      WordWithDifficulty('Baileys', difficulty: 3),
      WordWithDifficulty('Corona', difficulty: 3),
      WordWithDifficulty('Budweiser', difficulty: 3),
      WordWithDifficulty('Guinness', difficulty: 3),
      WordWithDifficulty('Leffe', difficulty: 3),
      WordWithDifficulty('Grimbergen', difficulty: 3),
      WordWithDifficulty('Stella Artois', difficulty: 3),
      WordWithDifficulty('Jupiler', difficulty: 3),
      WordWithDifficulty('Affligem', difficulty: 2),

      // MARQUES D'ALCOOL/SPIRITUEUX - Difficile
      WordWithDifficulty('Chivas', difficulty: 3),
      WordWithDifficulty('Jameson', difficulty: 3),
      WordWithDifficulty('Grey Goose', difficulty: 3),
      WordWithDifficulty('Bombay Sapphire', difficulty: 3),
      WordWithDifficulty('Havana Club', difficulty: 3),
      WordWithDifficulty('Hennessy', difficulty: 3),
      WordWithDifficulty('Rémy Martin', difficulty: 3),
      WordWithDifficulty('Moët & Chandon', difficulty: 3),
      WordWithDifficulty('Veuve Clicquot', difficulty: 3),
      WordWithDifficulty('Dom Pérignon', difficulty: 3),
      WordWithDifficulty('Jägermeister', difficulty: 3),

      // MARQUES DE CONSOLES/JEUX VIDÉO - Facile
      WordWithDifficulty('Nintendo', difficulty: 1),
      WordWithDifficulty('PlayStation', difficulty: 1),
      WordWithDifficulty('Xbox', difficulty: 1),
      WordWithDifficulty('FIFA', difficulty: 1),
      WordWithDifficulty('Mario', difficulty: 1),
      WordWithDifficulty('Pokémon', difficulty: 1),

      // MARQUES DE CONSOLES/JEUX VIDÉO - Moyen
      WordWithDifficulty('Sega', difficulty: 3),
      WordWithDifficulty('Atari', difficulty: 3),
      WordWithDifficulty('Game Boy', difficulty: 2),
      WordWithDifficulty('Call of Duty', difficulty: 2),
      WordWithDifficulty('Assassin\'s Creed', difficulty: 2),
      WordWithDifficulty('Grand Theft Auto', difficulty: 2),
      WordWithDifficulty('Minecraft', difficulty: 2),
      WordWithDifficulty('Fortnite', difficulty: 2),
      WordWithDifficulty('The Sims', difficulty: 2),
      WordWithDifficulty('Zelda', difficulty: 2),

      // MARQUES DE CONSOLES/JEUX VIDÉO - Difficile
      WordWithDifficulty('Game Cube', difficulty: 2),

      // MARQUES DE MONTRES/BIJOUX - Facile
      WordWithDifficulty('Casio', difficulty: 2),
      WordWithDifficulty('Swatch', difficulty: 3),
      WordWithDifficulty('Fossil', difficulty: 2),

      // MARQUES DE MONTRES/BIJOUX - Moyen
      WordWithDifficulty('Tissot', difficulty: 3),
      WordWithDifficulty('Seiko', difficulty: 3),
      WordWithDifficulty('Longines', difficulty: 3),
      WordWithDifficulty('Tag Heuer', difficulty: 3),
      WordWithDifficulty('Michael Kors', difficulty: 3),
      WordWithDifficulty('Pandora', difficulty: 3),

      // MARQUES DE MONTRES/BIJOUX - Difficile
      WordWithDifficulty('Rolex', difficulty: 2),
      WordWithDifficulty('Omega', difficulty: 3),
      WordWithDifficulty('Cartier', difficulty: 3),
      WordWithDifficulty('Breitling', difficulty: 3),
      WordWithDifficulty('Hublot', difficulty: 3),
      WordWithDifficulty('Bulgari', difficulty: 3),
      WordWithDifficulty('Tiffany & Co', difficulty: 3),

      // MARQUES DE PARFUMS - Moyen
      WordWithDifficulty('Chanel N°5', difficulty: 2),
      WordWithDifficulty('Jean Paul Gaultier', difficulty: 2),
      WordWithDifficulty('Hugo Boss', difficulty: 2),
      WordWithDifficulty('Yves Saint Laurent', difficulty: 2),
      WordWithDifficulty('Giorgio Armani', difficulty: 3),
      WordWithDifficulty('Dior Sauvage', difficulty: 3),
      WordWithDifficulty('Givenchy', difficulty: 3),

      // MARQUES DE PARFUMS - Difficile
      WordWithDifficulty('Terre d\'Hermès', difficulty: 3),
      WordWithDifficulty('Bleu de Chanel', difficulty: 3),
      WordWithDifficulty('One Million', difficulty: 3),
      WordWithDifficulty('L\'Homme', difficulty: 3),
      WordWithDifficulty('Acqua di Gio', difficulty: 3),
      WordWithDifficulty('La Vie est Belle', difficulty: 3),
      WordWithDifficulty('Black Opium', difficulty: 3),
      WordWithDifficulty('J\'adore', difficulty: 3),

      // MARQUES DE STREAMING/PLATEFORMES - Facile
      WordWithDifficulty('Netflix', difficulty: 1),
      WordWithDifficulty('YouTube', difficulty: 1),
      WordWithDifficulty('Spotify', difficulty: 1),
      WordWithDifficulty('Amazon Prime', difficulty: 1),
      WordWithDifficulty('Disney+', difficulty: 1),

      // MARQUES DE STREAMING/PLATEFORMES - Moyen
      WordWithDifficulty('Deezer', difficulty: 2),
      WordWithDifficulty('Apple Music', difficulty: 2),
      WordWithDifficulty('Twitch', difficulty: 2),
      WordWithDifficulty('TikTok', difficulty: 2),
      WordWithDifficulty('HBO Max', difficulty: 2),
      WordWithDifficulty('Paramount+', difficulty:3),

      // MARQUES DE STREAMING/PLATEFORMES - Difficile
      WordWithDifficulty('Canal+ Séries', difficulty: 3),
      WordWithDifficulty('OCS', difficulty: 3),
      WordWithDifficulty('Salto', difficulty: 3),
      WordWithDifficulty('Apple TV+', difficulty: 3),
      WordWithDifficulty('Crunchyroll', difficulty: 3),

      // MARQUES AÉRIENNES - Facile
      WordWithDifficulty('Air France', difficulty: 3),
      WordWithDifficulty('Ryanair', difficulty: 3),
      WordWithDifficulty('EasyJet', difficulty: 2),

      // MARQUES AÉRIENNES - Moyen
      WordWithDifficulty('Emirates', difficulty: 3),
      WordWithDifficulty('Lufthansa', difficulty: 3),
      WordWithDifficulty('British Airways', difficulty: 3),
      WordWithDifficulty('Transavia', difficulty: 3),
      WordWithDifficulty('KLM', difficulty: 3),
      WordWithDifficulty('Vueling', difficulty: 3),
      WordWithDifficulty('Air Caraibes', difficulty: 3),

      // MARQUES AÉRIENNES - Difficile
      WordWithDifficulty('Qatar Airways', difficulty: 3),
      WordWithDifficulty('Etihad', difficulty: 3),
      WordWithDifficulty('Singapore Airlines', difficulty: 3),
      WordWithDifficulty('Turkish Airlines', difficulty: 3),

      // MARQUES DE MOTOS - Facile
      WordWithDifficulty('Harley-Davidson', difficulty: 2),
      WordWithDifficulty('Yamaha', difficulty: 2),
      WordWithDifficulty('Kawasaki', difficulty: 3),

      // MARQUES DE MOTOS - Moyen
      WordWithDifficulty('Ducati', difficulty: 3),
      WordWithDifficulty('Suzuki', difficulty: 3),
      WordWithDifficulty('BMW Motorrad', difficulty: 3),
      WordWithDifficulty('KTM', difficulty: 3),
      WordWithDifficulty('Triumph', difficulty: 3),


      // MARQUES D'HÔTELLERIE - Facile
      WordWithDifficulty('Ibis', difficulty: 1),
      WordWithDifficulty('Formule 1', difficulty: 1),
      WordWithDifficulty('Novotel', difficulty: 1),
      WordWithDifficulty('Mercure', difficulty: 1),

      // MARQUES D'HÔTELLERIE - Moyen
      WordWithDifficulty('Sofitel', difficulty: 2),
      WordWithDifficulty('Campanile', difficulty: 3),
      WordWithDifficulty('Kyriad', difficulty: 3),
      WordWithDifficulty('B&B Hotels', difficulty: 3),
      WordWithDifficulty('Hilton', difficulty: 2),
      WordWithDifficulty('Marriott', difficulty: 3),

      // MARQUES DE PRESSE/MÉDIAS - Facile
      WordWithDifficulty('Le Monde', difficulty: 1),
      WordWithDifficulty('Le Figaro', difficulty: 1),
      WordWithDifficulty('TF1', difficulty: 1),
      WordWithDifficulty('France 2', difficulty: 1),
      WordWithDifficulty('M6', difficulty: 1),

      // MARQUES DE PRESSE/MÉDIAS - Moyen
      WordWithDifficulty('Canal+', difficulty: 2),
      WordWithDifficulty('France 3', difficulty: 2),
      WordWithDifficulty('Arte', difficulty: 2),
      WordWithDifficulty('L\'Équipe', difficulty: 2),
      WordWithDifficulty('Le Parisien', difficulty: 2),
      WordWithDifficulty('Libération', difficulty: 2),
      WordWithDifficulty('20 Minutes', difficulty: 2),
      WordWithDifficulty('RTL', difficulty: 2),
      WordWithDifficulty('Europe 1', difficulty: 2),
      WordWithDifficulty('RMC', difficulty: 3),

      // MARQUES DE PRESSE/MÉDIAS - Difficile
      WordWithDifficulty('Les Échos', difficulty: 2),
      WordWithDifficulty('L\'Obs', difficulty: 3),
      WordWithDifficulty('Marianne', difficulty: 3),
      WordWithDifficulty('Le Point', difficulty: 3),
      WordWithDifficulty('L\'Express', difficulty: 3),
      WordWithDifficulty('Challenges', difficulty: 3),
      WordWithDifficulty('Courrier International', difficulty: 3),
      WordWithDifficulty('France Info', difficulty: 3),

  ],
);
