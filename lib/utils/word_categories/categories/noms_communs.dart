// ============================================================
// CATÉGORIE : Noms communs
// ============================================================
//
// DESCRIPTION :
// Objets physiques du quotidien, équipements, vêtements,
// outils et accessoires de la vie courante.
//
// SECTIONS EXISTANTES :
// - Objets électroniques (téléphone, ordinateur, télévision)
// - Objets quotidiens (clés, lunettes, parapluie)
// - Mobilier (chaise, table, armoire, lit)
// - Ustensiles de cuisine (casserole, couteau, fourchette)
// - Outils (marteau, tournevis, perceuse)
// - Transports et véhicules (voiture, vélo, avion)
// - Vêtements et chaussures (pantalon, chemise, basket)
// - Accessoires mode (ceinture, sac, chapeau)
// - Instruments de musique (guitare, piano, batterie)
// - Maison et habitat (porte, fenêtre, escalier)
// - Jouets (ballon, poupée, lego)
// - Électroménager (lave-linge, four, aspirateur)
// - Équipements sportifs (raquette, ballon, crampon)
// - Objets plage/vacances (parasol, bouée, tuba)
// - Matériel médical (thermomètre, béquille, bandage)
// - Matériel informatique (clavier, souris, écran)
// - Textiles (drap, serviette, rideau)
// - Contenants (boîte, sac, panier)
// - Décoration (cadre, vase, coussin)
//
// IDÉES D'ENRICHISSEMENT :
// - Fournitures de bureau (agrafeuse, classeur, post-it)
// - Matériel de jardinage (râteau, arrosoir, sécateur)
// - Équipement bébé (biberon, poussette, couche)
// - Matériel scolaire (cahier, règle, compas)
// - Équipement cuisine pro (mandoline, chinois, fouet)
// - Accessoires auto (GPS, dashcam, antivol)
//
// CRITÈRES DE DIFFICULTÉ :
// - 1 (Facile) : Objets universels (chaise, téléphone, voiture)
// - 2 (Moyen) : Moins courant mais connu (monocle, théière)
// - 3 (Difficile) : Spécialisé ou technique (trusquin, mandoline)
//
// ============================================================

import '../models.dart';

const categoryNomsCommuns = WordCategory(
  id: 'noms_communs',
  name: 'Noms communs',
  icon: '🔧',
  words: [

      // OBJETS ÉLECTRONIQUES - Facile
      WordWithDifficulty('Téléphone', difficulty: 1),
      WordWithDifficulty('Ordinateur', difficulty: 1),
      WordWithDifficulty('Télévision', difficulty: 1),
      WordWithDifficulty('Radio', difficulty: 1),
      WordWithDifficulty('Appareil photo', difficulty: 1),
      WordWithDifficulty('Console de jeux', difficulty: 1),

      // OBJETS ÉLECTRONIQUES - Moyen
      WordWithDifficulty('Tablette', difficulty: 1),
      WordWithDifficulty('Casque', difficulty: 1),
      WordWithDifficulty('Enceinte', difficulty: 2),
      WordWithDifficulty('Chargeur', difficulty: 1),
      WordWithDifficulty('Clé USB', difficulty: 2),
      WordWithDifficulty('Clavier', difficulty: 2),
      WordWithDifficulty('Souris', difficulty: 2),
      WordWithDifficulty('Imprimante', difficulty: 2),
      WordWithDifficulty('Scanner', difficulty: 2),

      // OBJETS ÉLECTRONIQUES - Difficile
      WordWithDifficulty('Webcam', difficulty: 3),
      WordWithDifficulty('Drone', difficulty: 3),
      WordWithDifficulty('Projecteur', difficulty: 3),
      WordWithDifficulty('Disque dur', difficulty: 3),
      WordWithDifficulty('Carte mémoire', difficulty: 3),

      // OBJETS QUOTIDIEN - Facile
      WordWithDifficulty('Stylo', difficulty: 1),
      WordWithDifficulty('Crayon', difficulty: 1),
      WordWithDifficulty('Cahier', difficulty: 1),
      WordWithDifficulty('Livre', difficulty: 1),
      WordWithDifficulty('Parapluie', difficulty: 1),
      WordWithDifficulty('Sac', difficulty: 1),
      WordWithDifficulty('Valise', difficulty: 1),
      WordWithDifficulty('Montre', difficulty: 1),
      WordWithDifficulty('Lunettes', difficulty: 1),
      WordWithDifficulty('Clés', difficulty: 1),
      WordWithDifficulty('Sac à dos', difficulty: 1),
      WordWithDifficulty('Brosse à dents', difficulty: 1),
      WordWithDifficulty('Peigne', difficulty: 1),
      WordWithDifficulty('Savon', difficulty: 1),
      WordWithDifficulty('Serviette', difficulty: 1),
      WordWithDifficulty('Télécommande', difficulty: 1),

      // OBJETS QUOTIDIEN - Moyen
      WordWithDifficulty('Lampe', difficulty: 1),
      WordWithDifficulty('Horloge', difficulty: 2),
      WordWithDifficulty('Réveil', difficulty: 1),
      WordWithDifficulty('Bougie', difficulty: 2),
      WordWithDifficulty('Vase', difficulty: 2),
      WordWithDifficulty('Cadre photo', difficulty: 2),
      WordWithDifficulty('Panier', difficulty: 2),
      WordWithDifficulty('Ciseaux', difficulty: 2),
      WordWithDifficulty('Règle', difficulty: 2),

      // OBJETS QUOTIDIEN - Difficile
      WordWithDifficulty('Portefeuille', difficulty: 3),
      WordWithDifficulty('Briquet', difficulty: 3),
      WordWithDifficulty('Boussole', difficulty: 3),
      WordWithDifficulty('Loupe', difficulty: 3),
      WordWithDifficulty('Jumelles', difficulty: 3),
      WordWithDifficulty('Théière', difficulty: 3),

      // MOBILIER - Facile
      WordWithDifficulty('Chaise', difficulty: 1),
      WordWithDifficulty('Table', difficulty: 1),
      WordWithDifficulty('Lit', difficulty: 1),
      WordWithDifficulty('Canapé', difficulty: 1),
      WordWithDifficulty('Armoire', difficulty: 1),
      WordWithDifficulty('Placard', difficulty: 1),

      // MOBILIER - Moyen
      WordWithDifficulty('Bureau', difficulty: 2),
      WordWithDifficulty('Fauteuil', difficulty: 2),
      WordWithDifficulty('Étagère', difficulty: 2),
      WordWithDifficulty('Commode', difficulty: 2),
      WordWithDifficulty('Bibliothèque', difficulty: 2),
      WordWithDifficulty('Tabouret', difficulty: 2),
      WordWithDifficulty('Tapis', difficulty: 2),
      WordWithDifficulty('Rideau', difficulty: 2),
      WordWithDifficulty('Miroir', difficulty: 2),
      WordWithDifficulty('Lampadaire', difficulty: 2),
      WordWithDifficulty('Table de chevet', difficulty: 3),

      // MOBILIER - Difficile
      WordWithDifficulty('Banc', difficulty: 2),
      WordWithDifficulty('Pouf', difficulty: 3),
      WordWithDifficulty('Matelas', difficulty: 2),
      WordWithDifficulty('Oreiller', difficulty: 1),
      WordWithDifficulty('Couverture', difficulty: 1),
      WordWithDifficulty('Lustre', difficulty: 3),
      WordWithDifficulty('Buffet', difficulty: 2),
      WordWithDifficulty('Console', difficulty: 2),

      // USTENSILES CUISINE - Facile
      WordWithDifficulty('Couteau', difficulty: 1),
      WordWithDifficulty('Fourchette', difficulty: 1),
      WordWithDifficulty('Cuillère', difficulty: 1),
      WordWithDifficulty('Assiette', difficulty: 1),
      WordWithDifficulty('Verre', difficulty: 1),
      WordWithDifficulty('Tasse', difficulty: 1),

      // USTENSILES CUISINE - Moyen
      WordWithDifficulty('Casserole', difficulty: 2),
      WordWithDifficulty('Poêle', difficulty: 2),
      WordWithDifficulty('Passoire', difficulty: 2),
      WordWithDifficulty('Fouet', difficulty: 2),
      WordWithDifficulty('Spatule', difficulty: 2),
      WordWithDifficulty('Louche', difficulty: 2),
      WordWithDifficulty('Saladier', difficulty: 2),

      // USTENSILES CUISINE - Difficile
      WordWithDifficulty('Écumoire', difficulty: 3),
      WordWithDifficulty('Chinois', difficulty: 3),
      WordWithDifficulty('Mandoline', difficulty: 3),
      WordWithDifficulty('Presse-agrumes', difficulty: 3),

      // OUTILS - Facile
      WordWithDifficulty('Marteau', difficulty: 1),
      WordWithDifficulty('Tournevis', difficulty: 1),
      WordWithDifficulty('Scie', difficulty: 1),

      // OUTILS - Moyen
      WordWithDifficulty('Perceuse', difficulty: 2),
      WordWithDifficulty('Pince', difficulty: 2),
      WordWithDifficulty('Clé', difficulty: 2),
      WordWithDifficulty('Niveau', difficulty: 2),
      WordWithDifficulty('Mètre', difficulty: 2),

      // OUTILS - Difficile
      WordWithDifficulty('Rabot', difficulty: 3),
      WordWithDifficulty('Étau', difficulty: 3),
      WordWithDifficulty('Serre-joint', difficulty: 3),
      WordWithDifficulty('Lime', difficulty: 3),

      // MOYENS DE TRANSPORT - Facile
      WordWithDifficulty('Voiture', difficulty: 1),
      WordWithDifficulty('Avion', difficulty: 1),
      WordWithDifficulty('Train', difficulty: 1),
      WordWithDifficulty('Bateau', difficulty: 1),
      WordWithDifficulty('Vélo', difficulty: 1),
      WordWithDifficulty('Bus', difficulty: 1),
      WordWithDifficulty('Métro', difficulty: 1),
      WordWithDifficulty('Scooter', difficulty: 1),

      // MOYENS DE TRANSPORT - Moyen
      WordWithDifficulty('Moto', difficulty: 2),
      WordWithDifficulty('Camion', difficulty: 2),
      WordWithDifficulty('Tramway', difficulty: 2),
      WordWithDifficulty('Taxi', difficulty: 2),
      WordWithDifficulty('Hélicoptère', difficulty: 2),
      WordWithDifficulty('Voilier', difficulty: 2),
      WordWithDifficulty('Péniche', difficulty: 2),
      WordWithDifficulty('Ferry', difficulty: 2),

      // MOYENS DE TRANSPORT - Difficile
      WordWithDifficulty('Fusée', difficulty: 3),
      WordWithDifficulty('Sous-marin', difficulty: 3),
      WordWithDifficulty('Montgolfière', difficulty: 3),
      WordWithDifficulty('Parachute', difficulty: 2),
      WordWithDifficulty('Ascenseur', difficulty: 2),
      WordWithDifficulty('Escalator', difficulty: 2),
      WordWithDifficulty('Trottinette', difficulty: 2),
      WordWithDifficulty('Skateboard', difficulty: 2),
      WordWithDifficulty('Téléphérique', difficulty: 3),

      // VÊTEMENTS - Facile
      WordWithDifficulty('T-shirt', difficulty: 1),
      WordWithDifficulty('Pantalon', difficulty: 1),
      WordWithDifficulty('Robe', difficulty: 1),
      WordWithDifficulty('Jupe', difficulty: 1),
      WordWithDifficulty('Chaussures', difficulty: 1),
      WordWithDifficulty('Chaussettes', difficulty: 1),
      WordWithDifficulty('Manteau', difficulty: 1),

      // VÊTEMENTS - Moyen
      WordWithDifficulty('Pull', difficulty: 2),
      WordWithDifficulty('Chemise', difficulty: 2),
      WordWithDifficulty('Veste', difficulty: 2),
      WordWithDifficulty('Écharpe', difficulty: 2),
      WordWithDifficulty('Gants', difficulty: 2),
      WordWithDifficulty('Bonnet', difficulty: 2),
      WordWithDifficulty('Cravate', difficulty: 2),

      // VÊTEMENTS - Difficile
      WordWithDifficulty('Gilet', difficulty: 3),
      WordWithDifficulty('Cardigan', difficulty: 3),
      WordWithDifficulty('Pardessus', difficulty: 3),
      WordWithDifficulty('Chapka', difficulty: 3),

      // INSTRUMENTS À CORDES - Facile
      WordWithDifficulty('Guitare', difficulty: 1),
      WordWithDifficulty('Piano', difficulty: 1),
      WordWithDifficulty('Violon', difficulty: 1),

      // INSTRUMENTS À CORDES - Moyen
      WordWithDifficulty('Harpe', difficulty: 2),
      WordWithDifficulty('Violoncelle', difficulty: 2),
      WordWithDifficulty('Contrebasse', difficulty: 2),
      WordWithDifficulty('Ukulélé', difficulty: 2),
      WordWithDifficulty('Banjo', difficulty: 2),

      // INSTRUMENTS À CORDES - Difficile
      WordWithDifficulty('Alto', difficulty: 3),
      WordWithDifficulty('Clavecin', difficulty: 3),
      WordWithDifficulty('Luth', difficulty: 3),

      // INSTRUMENTS À VENT - Facile
      WordWithDifficulty('Flûte', difficulty: 1),
      WordWithDifficulty('Trompette', difficulty: 1),
      WordWithDifficulty('Saxophone', difficulty: 1),

      // INSTRUMENTS À VENT - Moyen
      WordWithDifficulty('Clarinette', difficulty: 2),
      WordWithDifficulty('Trombone', difficulty: 2),
      WordWithDifficulty('Cor', difficulty: 2),
      WordWithDifficulty('Harmonica', difficulty: 2),

      // INSTRUMENTS À VENT - Difficile
      WordWithDifficulty('Hautbois', difficulty: 3),
      WordWithDifficulty('Basson', difficulty: 3),
      WordWithDifficulty('Tuba', difficulty: 3),
      WordWithDifficulty('Cornemuse', difficulty: 3),
      WordWithDifficulty('Ocarina', difficulty: 3),

      // INSTRUMENTS À PERCUSSION - Facile
      WordWithDifficulty('Batterie', difficulty: 1),
      WordWithDifficulty('Tambour', difficulty: 1),
      WordWithDifficulty('Xylophone', difficulty: 1),

      // INSTRUMENTS À PERCUSSION - Moyen
      WordWithDifficulty('Cymbales', difficulty: 3),
      WordWithDifficulty('Maracas', difficulty: 2),
      WordWithDifficulty('Djembé', difficulty: 2),
      WordWithDifficulty('Gong', difficulty: 3),

      // INSTRUMENTS À PERCUSSION - Difficile
      WordWithDifficulty('Timbales', difficulty: 3),
      WordWithDifficulty('Triangle', difficulty: 2),

      // INVENTIONS - Facile
      WordWithDifficulty('Roue', difficulty: 1),
      WordWithDifficulty('Ampoule', difficulty: 1),
      WordWithDifficulty('Internet', difficulty: 1),

      // INVENTIONS - Moyen
      WordWithDifficulty('Imprimerie', difficulty: 2),
      WordWithDifficulty('Télégraphe', difficulty: 2),
      WordWithDifficulty('Microscope', difficulty: 2),
      WordWithDifficulty('Vaccin', difficulty: 2),
      WordWithDifficulty('Moteur à explosion', difficulty: 3),
      WordWithDifficulty('Locomotive', difficulty: 2),

      // INVENTIONS - Difficile
      WordWithDifficulty('Pénicilline', difficulty: 3),
      WordWithDifficulty('Anesthésie', difficulty: 2),
      WordWithDifficulty('Radiographie', difficulty: 3),
      WordWithDifficulty('Microprocesseur', difficulty: 3),
      WordWithDifficulty('GPS', difficulty: 3),
      WordWithDifficulty('Wi-Fi', difficulty: 2),
      WordWithDifficulty('Bluetooth', difficulty: 2),
      WordWithDifficulty('Code-barres', difficulty: 2),
      WordWithDifficulty('Fermeture éclair', difficulty: 3),
      WordWithDifficulty('Velcro', difficulty: 3),
      WordWithDifficulty('Post-it', difficulty: 2),
      WordWithDifficulty('Laser', difficulty: 2),

      // MAISON & HABITAT - Pièces - Facile
      WordWithDifficulty('Cuisine', difficulty: 1),
      WordWithDifficulty('Chambre', difficulty: 1),
      WordWithDifficulty('Salon', difficulty: 1),
      WordWithDifficulty('Salle de bain', difficulty: 1),
      WordWithDifficulty('Garage', difficulty: 1),

      // MAISON & HABITAT - Pièces - Moyen
      WordWithDifficulty('Cave', difficulty: 2),
      WordWithDifficulty('Grenier', difficulty: 2),
      WordWithDifficulty('Couloir', difficulty: 1),
      WordWithDifficulty('Entrée', difficulty: 1),
      WordWithDifficulty('Terrasse', difficulty: 2),
      WordWithDifficulty('Balcon', difficulty: 2),

      // MAISON & HABITAT - Pièces - Difficile
      WordWithDifficulty('Buanderie', difficulty: 2),
      WordWithDifficulty('Cellier', difficulty: 2),
      WordWithDifficulty('Véranda', difficulty: 2),
      WordWithDifficulty('Vestibule', difficulty: 3),

      // MAISON & HABITAT - Éléments construction - Facile
      WordWithDifficulty('Porte', difficulty: 1),
      WordWithDifficulty('Fenêtre', difficulty: 1),
      WordWithDifficulty('Mur', difficulty: 1),
      WordWithDifficulty('Toit', difficulty: 1),
      WordWithDifficulty('Escalier', difficulty: 1),

      // MAISON & HABITAT - Éléments construction - Moyen
      WordWithDifficulty('Cheminée', difficulty: 2),
      WordWithDifficulty('Plafond', difficulty: 2),
      WordWithDifficulty('Sol', difficulty: 2),
      WordWithDifficulty('Volet', difficulty: 2),
      WordWithDifficulty('Radiateur', difficulty: 2),
      WordWithDifficulty('Interrupteur', difficulty: 2),
      WordWithDifficulty('Prise', difficulty: 2),

      // MAISON & HABITAT - Éléments construction - Difficile
      WordWithDifficulty('Plinthe', difficulty: 3),
      WordWithDifficulty('Corniche', difficulty: 3),
      WordWithDifficulty('Gouttière', difficulty: 2),
      WordWithDifficulty('Charpente', difficulty: 2),
      WordWithDifficulty('Tuile', difficulty: 2),
      WordWithDifficulty('Ardoise', difficulty: 2),

      // MAISON & HABITAT - Bâtiments - Facile
      WordWithDifficulty('Maison', difficulty: 1),
      WordWithDifficulty('Immeuble', difficulty: 1),
      WordWithDifficulty('École', difficulty: 1),
      WordWithDifficulty('Hôpital', difficulty: 1),
      WordWithDifficulty('Église', difficulty: 1),

      // MAISON & HABITAT - Bâtiments - Moyen
      WordWithDifficulty('Château', difficulty: 2),
      WordWithDifficulty('Pont', difficulty: 2),
      WordWithDifficulty('Tour', difficulty: 2),
      WordWithDifficulty('Musée', difficulty: 2),
      WordWithDifficulty('Gare', difficulty: 2),
      WordWithDifficulty('Aéroport', difficulty: 2),

      // MAISON & HABITAT - Bâtiments - Difficile
      WordWithDifficulty('Cathédrale', difficulty: 2),
      WordWithDifficulty('Beffroi', difficulty: 3),
      WordWithDifficulty('Phare', difficulty: 2),
      WordWithDifficulty('Donjon', difficulty: 2),
      WordWithDifficulty('Aqueduc', difficulty: 3),

      // ÉDUCATION & LOISIRS - Matériel scolaire - Facile
      WordWithDifficulty('Cartable', difficulty: 1),
      WordWithDifficulty('Trousse', difficulty: 1),
      WordWithDifficulty('Gomme', difficulty: 1),
      WordWithDifficulty('Taille-crayon', difficulty: 1),
      WordWithDifficulty('Feutre', difficulty: 1),
      WordWithDifficulty('Surligneur', difficulty: 1),

      // ÉDUCATION & LOISIRS - Matériel scolaire - Moyen
      WordWithDifficulty('Rapporteur', difficulty: 2),
      WordWithDifficulty('Compas', difficulty: 2),
      WordWithDifficulty('Équerre', difficulty: 2),
      WordWithDifficulty('Classeur', difficulty: 2),
      WordWithDifficulty('Cahier de texte', difficulty: 2),

      // ÉDUCATION & LOISIRS - Matériel scolaire - Difficile
      WordWithDifficulty('Plumier', difficulty: 3),
      WordWithDifficulty('Protège-cahier', difficulty: 3),
      WordWithDifficulty('Perforatrice', difficulty: 3),

      // ÉDUCATION & LOISIRS - Matériel bureau - Facile
      WordWithDifficulty('Agrafeuse', difficulty: 1),
      WordWithDifficulty('Trombones', difficulty: 1),
      WordWithDifficulty('Scotch', difficulty: 1),

      // ÉDUCATION & LOISIRS - Matériel bureau - Moyen
      WordWithDifficulty('Dégrafeuse', difficulty: 3),
      WordWithDifficulty('Colle', difficulty: 2),
      WordWithDifficulty('Punaises', difficulty: 2),
      WordWithDifficulty('Élastiques', difficulty: 2),

      // ÉDUCATION & LOISIRS - Matériel bureau - Difficile
      WordWithDifficulty('Massicot', difficulty: 3),
      WordWithDifficulty('Reliure', difficulty: 3),

      // ÉDUCATION & LOISIRS - Jouets - Facile
      WordWithDifficulty('Ballon', difficulty: 1),
      WordWithDifficulty('Poupée', difficulty: 1),
      WordWithDifficulty('Voiture miniature', difficulty: 1),
      WordWithDifficulty('Puzzle', difficulty: 1),
      WordWithDifficulty('Peluche', difficulty: 1),

      // ÉDUCATION & LOISIRS - Jouets - Moyen
      WordWithDifficulty('Jeu de société', difficulty: 2),
      WordWithDifficulty('Lego', difficulty: 2),
      WordWithDifficulty('Yo-yo', difficulty: 2),
      WordWithDifficulty('Toupie', difficulty: 2),
      WordWithDifficulty('Marionnette', difficulty: 2),
      WordWithDifficulty('Cerf-volant', difficulty: 2),

      // ÉDUCATION & LOISIRS - Jouets - Difficile
      WordWithDifficulty('Bilboquet', difficulty: 3),
      WordWithDifficulty('Diabolo', difficulty: 2),
      WordWithDifficulty('Kapla', difficulty: 2),
      WordWithDifficulty('Billes', difficulty: 2),

      // ÉDUCATION & LOISIRS - Sports - Facile
      WordWithDifficulty('Raquette', difficulty: 1),
      WordWithDifficulty('Ballon de foot', difficulty: 1),
      WordWithDifficulty('Basket', difficulty: 1),
      WordWithDifficulty('Skis', difficulty: 1),

      // ÉDUCATION & LOISIRS - Sports - Moyen
      WordWithDifficulty('Club de golf', difficulty: 2),
      WordWithDifficulty('Crosse de hockey', difficulty: 2),
      WordWithDifficulty('Arc', difficulty: 2),
      WordWithDifficulty('Flèche', difficulty: 2),
      WordWithDifficulty('Haltères', difficulty: 2),
      WordWithDifficulty('Corde à sauter', difficulty: 2),

      // EXTÉRIEUR & JARDINAGE - Facile
      WordWithDifficulty('Pelle', difficulty: 1),
      WordWithDifficulty('Râteau', difficulty: 1),
      WordWithDifficulty('Arrosoir', difficulty: 1),
      WordWithDifficulty('Tuyau', difficulty: 1),
      WordWithDifficulty('Seau', difficulty: 1),

      // EXTÉRIEUR & JARDINAGE - Moyen
      WordWithDifficulty('Brouette', difficulty: 2),
      WordWithDifficulty('Tondeuse', difficulty: 2),
      WordWithDifficulty('Tronçonneuse', difficulty: 2),
      WordWithDifficulty('Bêche', difficulty: 2),
      WordWithDifficulty('Pioche', difficulty: 2),
      WordWithDifficulty('Sécateur', difficulty: 2),
      WordWithDifficulty('Cisailles', difficulty: 3),

      // EXTÉRIEUR & JARDINAGE - Difficile
      WordWithDifficulty('Binette', difficulty: 3),

      // ACCESSOIRES & DÉCORATION - Bijoux - Facile
      WordWithDifficulty('Collier', difficulty: 1),
      WordWithDifficulty('Bracelet', difficulty: 1),
      WordWithDifficulty('Bague', difficulty: 1),
      WordWithDifficulty('Boucles d\'oreilles', difficulty: 1),

      // ACCESSOIRES & DÉCORATION - Bijoux - Moyen
      WordWithDifficulty('Broche', difficulty: 2),
      WordWithDifficulty('Pendentif', difficulty: 2),
      WordWithDifficulty('Médaillon', difficulty: 2),
      WordWithDifficulty('Chevalière', difficulty: 2),

      // ACCESSOIRES & DÉCORATION - Bijoux - Difficile
      WordWithDifficulty('Diadème', difficulty: 2),
      WordWithDifficulty('Parure', difficulty: 3),
      WordWithDifficulty('Jonc', difficulty: 3),

      // ACCESSOIRES & DÉCORATION - Récipients - Facile
      WordWithDifficulty('Boîte', difficulty: 1),
      WordWithDifficulty('Bocal', difficulty: 1),
      WordWithDifficulty('Bouteille', difficulty: 1),
      WordWithDifficulty('Sac plastique', difficulty: 1),

      // ACCESSOIRES & DÉCORATION - Récipients - Moyen
      WordWithDifficulty('Carafe', difficulty: 2),
      WordWithDifficulty('Cruche', difficulty: 2),
      WordWithDifficulty('Pot', difficulty: 2),
      WordWithDifficulty('Corbeille', difficulty: 2),
      WordWithDifficulty('Urne', difficulty: 2),

      // ACCESSOIRES & DÉCORATION - Récipients - Difficile
      WordWithDifficulty('Amphore', difficulty: 2),
      WordWithDifficulty('Fiole', difficulty: 2),
      WordWithDifficulty('Bonbonne', difficulty: 2),
      WordWithDifficulty('Flacon', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - ÉLECTROMÉNAGER
      // ============================================

      // GROS ÉLECTROMÉNAGER - Facile
      WordWithDifficulty('Réfrigérateur', difficulty: 1),
      WordWithDifficulty('Congélateur', difficulty: 1),
      WordWithDifficulty('Lave-linge', difficulty: 1),
      WordWithDifficulty('Lave-vaisselle', difficulty: 1),
      WordWithDifficulty('Four', difficulty: 1),
      WordWithDifficulty('Cuisinière', difficulty: 1),
      WordWithDifficulty('Sèche-linge', difficulty: 1),
      WordWithDifficulty('Climatiseur', difficulty: 2),
      WordWithDifficulty('Chauffe-eau', difficulty: 2),

      // PETIT ÉLECTROMÉNAGER - Facile
      WordWithDifficulty('Micro-ondes', difficulty: 1),
      WordWithDifficulty('Grille-pain', difficulty: 1),
      WordWithDifficulty('Cafetière', difficulty: 1),
      WordWithDifficulty('Bouilloire', difficulty: 1),
      WordWithDifficulty('Mixeur', difficulty: 1),
      WordWithDifficulty('Robot cuisine', difficulty: 1),
      WordWithDifficulty('Blender', difficulty: 1),
      WordWithDifficulty('Fer à repasser', difficulty: 1),
      WordWithDifficulty('Aspirateur', difficulty: 1),
      WordWithDifficulty('Ventilateur', difficulty: 1),
      WordWithDifficulty('Sèche-cheveux', difficulty: 1),

      // PETIT ÉLECTROMÉNAGER - Moyen
      WordWithDifficulty('Friteuse', difficulty: 2),
      WordWithDifficulty('Cuiseur vapeur', difficulty: 2),
      WordWithDifficulty('Gaufrier', difficulty: 2),
      WordWithDifficulty('Crêpière', difficulty: 2),
      WordWithDifficulty('Machine à pain', difficulty: 2),
      WordWithDifficulty('Machine à café', difficulty: 2),
      WordWithDifficulty('Centrifugeuse', difficulty: 2),
      WordWithDifficulty('Yaourtière', difficulty: 2),
      WordWithDifficulty('Raclette', difficulty: 2),
      WordWithDifficulty('Fondue', difficulty: 2),
      WordWithDifficulty('Plancha', difficulty: 2),
      WordWithDifficulty('Barbecue', difficulty: 1),

      // PETIT ÉLECTROMÉNAGER - Difficile
      WordWithDifficulty('Autocuiseur', difficulty: 2),
      WordWithDifficulty('Thermomix', difficulty: 2),
      WordWithDifficulty('Déshumidificateur', difficulty: 3),
      WordWithDifficulty('Humidificateur', difficulty: 3),
      WordWithDifficulty('Purificateur d\'air', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - ÉQUIPEMENTS SPORTIFS
      // ============================================

      // ÉQUIPEMENTS SPORT - Facile
      WordWithDifficulty('Ballon de basket', difficulty: 1),
      WordWithDifficulty('Ballon de rugby', difficulty: 1),
      WordWithDifficulty('Ballon de volley', difficulty: 1),
      WordWithDifficulty('Raquette de tennis', difficulty: 1),
      WordWithDifficulty('Raquette de ping-pong', difficulty: 1),
      WordWithDifficulty('Filet', difficulty: 1),
      WordWithDifficulty('But', difficulty: 1),
      WordWithDifficulty('Gant de boxe', difficulty: 1),
      WordWithDifficulty('Kimono', difficulty: 2),
      WordWithDifficulty('Genouillère', difficulty: 2),
      WordWithDifficulty('Protège-tibia', difficulty: 2),

      // ÉQUIPEMENTS SPORT - Moyen
      WordWithDifficulty('Crampon', difficulty: 2),
      WordWithDifficulty('Batte', difficulty: 2),
      WordWithDifficulty('Club', difficulty: 2),
      WordWithDifficulty('Palet', difficulty: 2),
      WordWithDifficulty('Crosse', difficulty: 2),
      WordWithDifficulty('Volant', difficulty: 2),
      WordWithDifficulty('Cible', difficulty: 2),
      WordWithDifficulty('Trampoline', difficulty: 1),
      WordWithDifficulty('Tapis de gym', difficulty: 2),
      WordWithDifficulty('Vélo elliptique', difficulty: 2),
      WordWithDifficulty('Rameur', difficulty: 2),
      WordWithDifficulty('Tapis de course', difficulty: 2),
      WordWithDifficulty('Stepper', difficulty: 2),
      WordWithDifficulty('Banc de musculation', difficulty: 2),
      WordWithDifficulty('Barre de traction', difficulty: 2),
      WordWithDifficulty('Kettlebell', difficulty: 2),
      WordWithDifficulty('Élastique', difficulty: 2),
      WordWithDifficulty('Ballon de gym', difficulty: 2),
      WordWithDifficulty('Roller', difficulty: 1),
      WordWithDifficulty('Patin à glace', difficulty: 2),
      WordWithDifficulty('Planche à roulettes', difficulty: 2),
      WordWithDifficulty('Surf', difficulty: 1),
      WordWithDifficulty('Bodyboard', difficulty: 2),
      WordWithDifficulty('Paddle', difficulty: 2),
      WordWithDifficulty('Kayak', difficulty: 2),
      WordWithDifficulty('Canoë', difficulty: 2),
      WordWithDifficulty('Bouée', difficulty: 1),
      WordWithDifficulty('Gilet de sauvetage', difficulty: 2),

      // ÉQUIPEMENTS SPORT - Difficile
      WordWithDifficulty('Épée', difficulty: 2),
      WordWithDifficulty('Fleuret', difficulty: 3),
      WordWithDifficulty('Sabre', difficulty: 2),
      WordWithDifficulty('Punching-ball', difficulty: 2),
      WordWithDifficulty('Punchingball', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - ACCESSOIRES MODE
      // ============================================

      // ACCESSOIRES MODE - Facile
      WordWithDifficulty('Ceinture', difficulty: 1),
      WordWithDifficulty('Chapeau', difficulty: 1),
      WordWithDifficulty('Casquette', difficulty: 1),
      WordWithDifficulty('Béret', difficulty: 2),
      WordWithDifficulty('Sac à main', difficulty: 1),
      WordWithDifficulty('Pochette', difficulty: 2),
      WordWithDifficulty('Foulard', difficulty: 2),
      WordWithDifficulty('Nœud papillon', difficulty: 2),
      WordWithDifficulty('Boutons de manchette', difficulty: 3),
      WordWithDifficulty('Bretelles', difficulty: 2),
      WordWithDifficulty('Paréo', difficulty: 2),

      // ACCESSOIRES MODE - Moyen
      WordWithDifficulty('Bandana', difficulty: 2),
      WordWithDifficulty('Turban', difficulty: 2),
      WordWithDifficulty('Bob', difficulty: 2),
      WordWithDifficulty('Fedora', difficulty: 3),
      WordWithDifficulty('Panama', difficulty: 3),
      WordWithDifficulty('Mitaines', difficulty: 2),
      WordWithDifficulty('Moufles', difficulty: 2),
      WordWithDifficulty('Cache-oreilles', difficulty: 2),
      WordWithDifficulty('Cagoule', difficulty: 2),

      // CHAUSSURES - Facile
      WordWithDifficulty('Baskets', difficulty: 1),
      WordWithDifficulty('Bottes', difficulty: 1),
      WordWithDifficulty('Sandales', difficulty: 1),
      WordWithDifficulty('Tongs', difficulty: 1),
      WordWithDifficulty('Escarpins', difficulty: 2),
      WordWithDifficulty('Mocassins', difficulty: 2),
      WordWithDifficulty('Ballerines', difficulty: 2),
      WordWithDifficulty('Bottines', difficulty: 2),
      WordWithDifficulty('Sabots', difficulty: 2),
      WordWithDifficulty('Pantoufles', difficulty: 1),
      WordWithDifficulty('Chaussons', difficulty: 1),
      WordWithDifficulty('Talons', difficulty: 2),
      WordWithDifficulty('Compensées', difficulty: 3),
      WordWithDifficulty('Derbies', difficulty: 3),
      WordWithDifficulty('Richelieu', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - OBJETS PLAGE/VACANCES
      // ============================================

      // OBJETS PLAGE - Facile
      WordWithDifficulty('Parasol', difficulty: 1),
      WordWithDifficulty('Transat', difficulty: 2),
      WordWithDifficulty('Serviette de plage', difficulty: 1),
      WordWithDifficulty('Crème solaire', difficulty: 1),
      WordWithDifficulty('Lunettes de soleil', difficulty: 1),
      WordWithDifficulty('Maillot de bain', difficulty: 1),
      WordWithDifficulty('Bikini', difficulty: 1),
      WordWithDifficulty('Masque de plongée', difficulty: 1),
      WordWithDifficulty('Palmes', difficulty: 2),
      WordWithDifficulty('Pelle de plage', difficulty: 1),
      WordWithDifficulty('Château de sable', difficulty: 1),
      WordWithDifficulty('Ballon de plage', difficulty: 1),
      WordWithDifficulty('Matelas gonflable', difficulty: 1),
      WordWithDifficulty('Glacière', difficulty: 1),
      WordWithDifficulty('Gourde', difficulty: 1),

      // OBJETS CAMPING/VOYAGE - Moyen
      WordWithDifficulty('Tente', difficulty: 1),
      WordWithDifficulty('Sac de couchage', difficulty: 1),
      WordWithDifficulty('Lampe torche', difficulty: 1),
      WordWithDifficulty('Réchaud', difficulty: 2),
      WordWithDifficulty('Gamelle', difficulty: 2),
      WordWithDifficulty('Canif', difficulty: 2),
      WordWithDifficulty('Hamac', difficulty: 2),
      WordWithDifficulty('Chaise pliante', difficulty: 2),
      WordWithDifficulty('Table pliante', difficulty: 2),
      WordWithDifficulty('Auvent', difficulty: 3),
      WordWithDifficulty('Caravane', difficulty: 1),
      WordWithDifficulty('Camping-car', difficulty: 1),

      // ============================================
      // ENRICHISSEMENT - MATÉRIEL MÉDICAL
      // ============================================

      // MATÉRIEL MÉDICAL - Facile
      WordWithDifficulty('Thermomètre', difficulty: 1),
      WordWithDifficulty('Pansement', difficulty: 1),
      WordWithDifficulty('Bandage', difficulty: 1),
      WordWithDifficulty('Compresse', difficulty: 2),
      WordWithDifficulty('Sparadrap', difficulty: 2),
      WordWithDifficulty('Béquille', difficulty: 1),
      WordWithDifficulty('Fauteuil roulant', difficulty: 1),
      WordWithDifficulty('Attelle', difficulty: 2),
      WordWithDifficulty('Plâtre', difficulty: 1),
      WordWithDifficulty('Seringue', difficulty: 1),
      WordWithDifficulty('Stéthoscope', difficulty: 1),
      WordWithDifficulty('Tensiomètre', difficulty: 2),
      WordWithDifficulty('Glucomètre', difficulty: 3),
      WordWithDifficulty('Inhalateur', difficulty: 2),

      // MATÉRIEL MÉDICAL - Moyen
      WordWithDifficulty('Civière', difficulty: 2),
      WordWithDifficulty('Brancard', difficulty: 2),
      WordWithDifficulty('Déambulateur', difficulty: 2),
      WordWithDifficulty('Minerve', difficulty: 3),
      WordWithDifficulty('Corset', difficulty: 2),
      WordWithDifficulty('Prothèse', difficulty: 2),
      WordWithDifficulty('Orthèse', difficulty: 3),
      WordWithDifficulty('Appareil auditif', difficulty: 2),
      WordWithDifficulty('Lunettes de vue', difficulty: 1),
      WordWithDifficulty('Lentilles', difficulty: 2),
      WordWithDifficulty('Poche de glace', difficulty: 2),
      WordWithDifficulty('Bouillotte', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - MATÉRIEL INFORMATIQUE
      // ============================================

      // MATÉRIEL INFORMATIQUE - Facile
      WordWithDifficulty('Écran', difficulty: 1),
      WordWithDifficulty('Moniteur', difficulty: 2),
      WordWithDifficulty('Ordinateur portable', difficulty: 1),
      WordWithDifficulty('Processeur', difficulty: 2),
      WordWithDifficulty('Carte graphique', difficulty: 2),
      WordWithDifficulty('Barrette RAM', difficulty: 3),
      WordWithDifficulty('Câble', difficulty: 1),
      WordWithDifficulty('Rallonge', difficulty: 1),
      WordWithDifficulty('Multiprise', difficulty: 1),
      WordWithDifficulty('Routeur', difficulty: 2),
      WordWithDifficulty('Box internet', difficulty: 1),
      WordWithDifficulty('Adaptateur', difficulty: 2),
      WordWithDifficulty('Hub USB', difficulty: 2),
      WordWithDifficulty('Batterie externe', difficulty: 2),
      WordWithDifficulty('Coque', difficulty: 1),
      WordWithDifficulty('Protection écran', difficulty: 2),
      WordWithDifficulty('Support téléphone', difficulty: 2),
      WordWithDifficulty('Trépi', difficulty: 2),
      WordWithDifficulty('Selfie stick', difficulty: 2),
      WordWithDifficulty('Microphone', difficulty: 1),
      WordWithDifficulty('Haut-parleur', difficulty: 1),
      WordWithDifficulty('Écouteurs', difficulty: 1),

      // ============================================
      // ENRICHISSEMENT - TEXTILES ET TISSUS
      // ============================================

      // TEXTILES MAISON - Facile
      WordWithDifficulty('Drap', difficulty: 1),
      WordWithDifficulty('Drap-housse', difficulty: 2),
      WordWithDifficulty('Couette', difficulty: 1),
      WordWithDifficulty('Taie d\'oreiller', difficulty: 2),
      WordWithDifficulty('Housse de couette', difficulty: 2),
      WordWithDifficulty('Plaid', difficulty: 2),
      WordWithDifficulty('Nappe', difficulty: 1),
      WordWithDifficulty('Serviette de table', difficulty: 2),
      WordWithDifficulty('Torchon', difficulty: 1),
      WordWithDifficulty('Gant de toilette', difficulty: 1),
      WordWithDifficulty('Peignoir', difficulty: 2),
      WordWithDifficulty('Coussin', difficulty: 1),
      WordWithDifficulty('Traversin', difficulty: 2),
      WordWithDifficulty('Édredon', difficulty: 3),
      WordWithDifficulty('Moquette', difficulty: 2),
      WordWithDifficulty('Store', difficulty: 2),
      WordWithDifficulty('Voilage', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - CONTENANTS ET EMBALLAGES
      // ============================================

      // CONTENANTS - Facile
      WordWithDifficulty('Sachet', difficulty: 1),
      WordWithDifficulty('Carton', difficulty: 1),
      WordWithDifficulty('Cagette', difficulty: 2),
      WordWithDifficulty('Caisse', difficulty: 1),
      WordWithDifficulty('Bac', difficulty: 1),
      WordWithDifficulty('Barquette', difficulty: 2),
      WordWithDifficulty('Tupperware', difficulty: 1),
      WordWithDifficulty('Boîte hermétique', difficulty: 2),
      WordWithDifficulty('Thermos', difficulty: 2),
      WordWithDifficulty('Conserve', difficulty: 1),
      WordWithDifficulty('Canette', difficulty: 1),
      WordWithDifficulty('Bidon', difficulty: 2),
      WordWithDifficulty('Jerrican', difficulty: 3),
      WordWithDifficulty('Tonneau', difficulty: 2),
      WordWithDifficulty('Baril', difficulty: 2),
      WordWithDifficulty('Paquet', difficulty: 1),
      WordWithDifficulty('Enveloppe', difficulty: 1),
      WordWithDifficulty('Tube', difficulty: 1),
      WordWithDifficulty('Spray', difficulty: 1),

      // ============================================
      // ENRICHISSEMENT - OBJETS DE DÉCORATION
      // ============================================

      // DÉCORATION - Facile
      WordWithDifficulty('Tableau', difficulty: 1),
      WordWithDifficulty('Poster', difficulty: 1),
      WordWithDifficulty('Affiche', difficulty: 1),
      WordWithDifficulty('Photo', difficulty: 1),
      WordWithDifficulty('Statue', difficulty: 2),
      WordWithDifficulty('Figurine', difficulty: 1),
      WordWithDifficulty('Bibelot', difficulty: 2),
      WordWithDifficulty('Horloge murale', difficulty: 1),
      WordWithDifficulty('Pendule', difficulty: 2),
      WordWithDifficulty('Bougeoir', difficulty: 2),
      WordWithDifficulty('Chandelier', difficulty: 2),
      WordWithDifficulty('Photophore', difficulty: 3),
      WordWithDifficulty('Guirlande', difficulty: 1),
      WordWithDifficulty('Couronne', difficulty: 2),
      WordWithDifficulty('Mobile', difficulty: 2),
      WordWithDifficulty('Trophée', difficulty: 2),
      WordWithDifficulty('Médaille', difficulty: 1),
      WordWithDifficulty('Coupe', difficulty: 1),
      WordWithDifficulty('Diplôme', difficulty: 1),
      WordWithDifficulty('Calendrier', difficulty: 1),
      WordWithDifficulty('Agenda', difficulty: 1),
      WordWithDifficulty('Album photo', difficulty: 1),
      WordWithDifficulty('Carnet', difficulty: 1),

      // ============================================
      // ENRICHISSEMENT - VÉHICULES SPÉCIFIQUES
      // ============================================

      // VÉHICULES - Moyen
      WordWithDifficulty('Ambulance', difficulty: 1),
      WordWithDifficulty('Pompier', difficulty: 1),
      WordWithDifficulty('Camion de pompier', difficulty: 1),
      WordWithDifficulty('Voiture de police', difficulty: 1),
      WordWithDifficulty('Corbillard', difficulty: 2),
      WordWithDifficulty('Dépanneuse', difficulty: 2),
      WordWithDifficulty('Benne', difficulty: 2),
      WordWithDifficulty('Bulldozer', difficulty: 2),
      WordWithDifficulty('Pelleteuse', difficulty: 2),
      WordWithDifficulty('Grue', difficulty: 1),
      WordWithDifficulty('Chariot élévateur', difficulty: 2),
      WordWithDifficulty('Tracteur', difficulty: 1),
      WordWithDifficulty('Moissonneuse', difficulty: 2),
      WordWithDifficulty('Remorque', difficulty: 2),
      WordWithDifficulty('Semi-remorque', difficulty: 2),
      WordWithDifficulty('Quad', difficulty: 2),
      WordWithDifficulty('Jet-ski', difficulty: 2),
      WordWithDifficulty('Yacht', difficulty: 2),
      WordWithDifficulty('Paquebot', difficulty: 2),
      WordWithDifficulty('Cargo', difficulty: 2),
      WordWithDifficulty('Pétrolier', difficulty: 2),
      WordWithDifficulty('Chalutier', difficulty: 3),
      WordWithDifficulty('Canot', difficulty: 2),
      WordWithDifficulty('Barque', difficulty: 2),
      WordWithDifficulty('Catamaran', difficulty: 2),
      WordWithDifficulty('Planeur', difficulty: 2),
      WordWithDifficulty('Deltaplane', difficulty: 2),
      WordWithDifficulty('ULM', difficulty: 3),
      WordWithDifficulty('Navette spatiale', difficulty: 2),
      WordWithDifficulty('Satellite', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - VÊTEMENTS SUPPLÉMENTAIRES
      // ============================================

      // VÊTEMENTS - Facile
      WordWithDifficulty('Short', difficulty: 1),
      WordWithDifficulty('Bermuda', difficulty: 2),
      WordWithDifficulty('Legging', difficulty: 1),
      WordWithDifficulty('Jogging', difficulty: 1),
      WordWithDifficulty('Survêtement', difficulty: 1),
      WordWithDifficulty('Polo', difficulty: 1),
      WordWithDifficulty('Sweat', difficulty: 1),
      WordWithDifficulty('Sweat à capuche', difficulty: 1),
      WordWithDifficulty('Débardeur', difficulty: 2),
      WordWithDifficulty('Bustier', difficulty: 2),
      WordWithDifficulty('Combinaison', difficulty: 2),
      WordWithDifficulty('Salopette', difficulty: 2),
      WordWithDifficulty('Costume', difficulty: 1),
      WordWithDifficulty('Smoking', difficulty: 2),
      WordWithDifficulty('Tailleur', difficulty: 2),
      WordWithDifficulty('Imperméable', difficulty: 2),
      WordWithDifficulty('Blouson', difficulty: 2),
      WordWithDifficulty('Doudoune', difficulty: 1),
      WordWithDifficulty('Parka', difficulty: 2),
      WordWithDifficulty('Trench', difficulty: 2),
      WordWithDifficulty('Cape', difficulty: 2),
      WordWithDifficulty('Poncho', difficulty: 2),
      WordWithDifficulty('K-way', difficulty: 2),
      WordWithDifficulty('Pyjama', difficulty: 1),
      WordWithDifficulty('Nuisette', difficulty: 2),
      WordWithDifficulty('Robe de chambre', difficulty: 2),

      // SOUS-VÊTEMENTS - Moyen
      WordWithDifficulty('Sous-vêtement', difficulty: 1),
      WordWithDifficulty('Slip', difficulty: 1),
      WordWithDifficulty('Caleçon', difficulty: 1),
      WordWithDifficulty('Boxer', difficulty: 1),
      WordWithDifficulty('Soutien-gorge', difficulty: 2),
      WordWithDifficulty('Culotte', difficulty: 1),
      WordWithDifficulty('Collant', difficulty: 2),
      WordWithDifficulty('Bas', difficulty: 2),
      WordWithDifficulty('Porte-jarretelles', difficulty: 3),
      WordWithDifficulty('Body', difficulty: 2),
      WordWithDifficulty('Caraco', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - OUTILS SUPPLÉMENTAIRES
      // ============================================

      // OUTILS - Moyen
      WordWithDifficulty('Visseuse', difficulty: 2),
      WordWithDifficulty('Ponceuse', difficulty: 2),
      WordWithDifficulty('Meuleuse', difficulty: 2),
      WordWithDifficulty('Scie sauteuse', difficulty: 2),
      WordWithDifficulty('Scie circulaire', difficulty: 2),
      WordWithDifficulty('Décapeur', difficulty: 3),
      WordWithDifficulty('Chalumeau', difficulty: 2),
      WordWithDifficulty('Fer à souder', difficulty: 2),
      WordWithDifficulty('Cutter', difficulty: 1),
      WordWithDifficulty('Fil à plomb', difficulty: 3),
      WordWithDifficulty('Mètre ruban', difficulty: 1),
      WordWithDifficulty('Pied de biche', difficulty: 3),
      WordWithDifficulty('Masse', difficulty: 2),
      WordWithDifficulty('Maillet', difficulty: 2),
      WordWithDifficulty('Burin', difficulty: 3),
      WordWithDifficulty('Ciseau à bois', difficulty: 3),

      // ============================================
      // ENRICHISSEMENT - USTENSILES CUISINE SUPPLÉMENTAIRES
      // ============================================

      // USTENSILES - Moyen
      WordWithDifficulty('Rouleau à pâtisserie', difficulty: 1),
      WordWithDifficulty('Moule à gâteau', difficulty: 1),
      WordWithDifficulty('Plaque de cuisson', difficulty: 2),
      WordWithDifficulty('Cocotte', difficulty: 2),
      WordWithDifficulty('Marmite', difficulty: 2),
      WordWithDifficulty('Sauteuse', difficulty: 2),
      WordWithDifficulty('Wok', difficulty: 2),
      WordWithDifficulty('Faitout', difficulty: 2),
      WordWithDifficulty('Tajine', difficulty: 2),
      WordWithDifficulty('Grill', difficulty: 2),
      WordWithDifficulty('Poêle à crêpes', difficulty: 2),
      WordWithDifficulty('Économe', difficulty: 2),
      WordWithDifficulty('Épluche-légumes', difficulty: 2),
      WordWithDifficulty('Ouvre-boîte', difficulty: 1),
      WordWithDifficulty('Tire-bouchon', difficulty: 1),
      WordWithDifficulty('Décapsuleur', difficulty: 2),
      WordWithDifficulty('Mortier', difficulty: 2),
      WordWithDifficulty('Pilon', difficulty: 2),
      WordWithDifficulty('Presse-ail', difficulty: 2),
      WordWithDifficulty('Râpe', difficulty: 1),
      WordWithDifficulty('Zesteur', difficulty: 3),
      WordWithDifficulty('Casse-noix', difficulty: 2),
      WordWithDifficulty('Pince à sucre', difficulty: 3),
      WordWithDifficulty('Pelle à tarte', difficulty: 2),
      WordWithDifficulty('Poche à douille', difficulty: 3),
      WordWithDifficulty('Tamis', difficulty: 2),
      WordWithDifficulty('Entonnoir', difficulty: 2),
      WordWithDifficulty('Balance', difficulty: 1),
      WordWithDifficulty('Minuteur', difficulty: 2),
      WordWithDifficulty('Thermomètre de cuisine', difficulty: 2),

      // ============================================
      // ENRICHISSEMENT - OBJETS DIVERS
      // ============================================

      // OBJETS DIVERS - Facile
      WordWithDifficulty('Porte-clés', difficulty: 1),
      WordWithDifficulty('Cadenas', difficulty: 1),
      WordWithDifficulty('Antivol', difficulty: 2),
      WordWithDifficulty('Badge', difficulty: 1),
      WordWithDifficulty('Carte de visite', difficulty: 2),
      WordWithDifficulty('Ticket', difficulty: 1),
      WordWithDifficulty('Billet', difficulty: 1),
      WordWithDifficulty('Pièce de monnaie', difficulty: 1),
      WordWithDifficulty('Carte bancaire', difficulty: 1),
      WordWithDifficulty('Carte d\'identité', difficulty: 1),
      WordWithDifficulty('Passeport', difficulty: 1),
      WordWithDifficulty('Permis de conduire', difficulty: 1),
      WordWithDifficulty('Carnet de santé', difficulty: 2),
      WordWithDifficulty('Ordonnance', difficulty: 2),
      WordWithDifficulty('Facture', difficulty: 1),
      WordWithDifficulty('Reçu', difficulty: 1),
      WordWithDifficulty('Contrat', difficulty: 2),
      WordWithDifficulty('Formulaire', difficulty: 2),

      // OBJETS DIVERS - Moyen
      WordWithDifficulty('Paravent', difficulty: 2),
      WordWithDifficulty('Poubelle', difficulty: 1),
      WordWithDifficulty('Cendrier', difficulty: 2),
      WordWithDifficulty('Porte-manteau', difficulty: 1),
      WordWithDifficulty('Patère', difficulty: 3),
      WordWithDifficulty('Cintre', difficulty: 1),
      WordWithDifficulty('Pèse-personne', difficulty: 2),
      WordWithDifficulty('Miroir de poche', difficulty: 2),
      WordWithDifficulty('Éventail', difficulty: 2),
      WordWithDifficulty('Ombrelle', difficulty: 2),
      WordWithDifficulty('Canne', difficulty: 2),
      WordWithDifficulty('Chapeau de pluie', difficulty: 2),

      // ============================================
      // FIN ENRICHISSEMENT NOMS COMMUNS
      // ============================================

  ],
);
