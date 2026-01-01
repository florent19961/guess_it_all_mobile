import '../models.dart';

const categoryMetiersSports = WordCategory(
  id: 'metiers_sports',
  name: 'Métiers',
  icon: '💼',
  words: [

      // MÉTIERS SANTÉ - Facile
      WordWithDifficulty('Médecin', difficulty: 1),
      WordWithDifficulty('Infirmier', difficulty: 1),
      WordWithDifficulty('Dentiste', difficulty: 1),
      WordWithDifficulty('Pharmacien', difficulty: 1),

      // MÉTIERS SANTÉ - Moyen
      WordWithDifficulty('Chirurgien', difficulty: 2),
      WordWithDifficulty('Vétérinaire', difficulty: 2),
      WordWithDifficulty('Sage-femme', difficulty: 2),
      WordWithDifficulty('Ambulancier', difficulty: 2),
      WordWithDifficulty('Radiologue', difficulty: 2),

      // MÉTIERS SANTÉ - Difficile
      WordWithDifficulty('Kinésithérapeute', difficulty: 2),
      WordWithDifficulty('Ostéopathe', difficulty: 2),
      WordWithDifficulty('Psychologue', difficulty: 2),
      WordWithDifficulty('Cardiologue', difficulty: 2),
      WordWithDifficulty('Dermatologue', difficulty: 2),
      WordWithDifficulty('Ophtalmologue', difficulty: 2),
      WordWithDifficulty('Pédiatre', difficulty: 2),
      WordWithDifficulty('Anesthésiste', difficulty: 3),
      WordWithDifficulty('Orthophoniste', difficulty: 3),
      WordWithDifficulty('Podologue', difficulty: 2),

      // MÉTIERS ÉDUCATION - Facile
      WordWithDifficulty('Professeur', difficulty: 1),
      WordWithDifficulty('Instituteur', difficulty: 1),
      WordWithDifficulty('Éducateur', difficulty: 1),

      // MÉTIERS ÉDUCATION - Moyen
      WordWithDifficulty('Directeur d\'école', difficulty: 2),
      WordWithDifficulty('Psychologue scolaire', difficulty: 2),
      WordWithDifficulty('Bibliothécaire', difficulty: 2),

      // MÉTIERS SÉCURITÉ - Facile
      WordWithDifficulty('Pompier', difficulty: 1),
      WordWithDifficulty('Policier', difficulty: 1),
      WordWithDifficulty('Gendarme', difficulty: 1),

      // MÉTIERS SÉCURITÉ - Moyen
      WordWithDifficulty('Militaire', difficulty: 2),
      WordWithDifficulty('Agent de sécurité', difficulty: 3),
      WordWithDifficulty('Maître-chien', difficulty: 3),

      // MÉTIERS SÉCURITÉ - Difficile
      WordWithDifficulty('Démineur', difficulty: 3),
      WordWithDifficulty('Garde du corps', difficulty: 3),

      // MÉTIERS ALIMENTATION - Facile
      WordWithDifficulty('Boulanger', difficulty: 1),
      WordWithDifficulty('Cuisinier', difficulty: 1),
      WordWithDifficulty('Serveur', difficulty: 1),

      // MÉTIERS ALIMENTATION - Moyen
      WordWithDifficulty('Pâtissier', difficulty: 2),
      WordWithDifficulty('Boucher', difficulty: 1),
      WordWithDifficulty('Poissonnier', difficulty: 1),
      WordWithDifficulty('Sommelier', difficulty: 2),
      WordWithDifficulty('Barman', difficulty: 2),
      WordWithDifficulty('Chef cuisinier', difficulty: 2),

      // MÉTIERS ALIMENTATION - Difficile
      WordWithDifficulty('Fromager', difficulty: 2),
      WordWithDifficulty('Chocolatier', difficulty: 2),
      WordWithDifficulty('Glacier', difficulty: 2),
      WordWithDifficulty('Traiteur', difficulty: 2),

      // MÉTIERS ARTISANAT - Facile
      WordWithDifficulty('Coiffeur', difficulty: 1),
      WordWithDifficulty('Mécanicien', difficulty: 1),
      WordWithDifficulty('Menuisier', difficulty: 1),

      // MÉTIERS ARTISANAT - Moyen
      WordWithDifficulty('Électricien', difficulty: 1),
      WordWithDifficulty('Plombier', difficulty: 1),
      WordWithDifficulty('Maçon', difficulty: 2),
      WordWithDifficulty('Peintre', difficulty: 1),
      WordWithDifficulty('Jardinier', difficulty: 1),
      WordWithDifficulty('Carreleur', difficulty: 3),

      // MÉTIERS ARTISANAT - Difficile
      WordWithDifficulty('Ébéniste', difficulty: 3),
      WordWithDifficulty('Charpentier', difficulty: 3),
      WordWithDifficulty('Serrurier', difficulty: 2),
      WordWithDifficulty('Couvreur', difficulty: 3),
      WordWithDifficulty('Tapissier', difficulty: 3),
      WordWithDifficulty('Vitrier', difficulty: 3),
      WordWithDifficulty('Forgeron', difficulty: 3),

      // MÉTIERS TRANSPORT - Facile
      WordWithDifficulty('Chauffeur', difficulty: 1),
      WordWithDifficulty('Conducteur de bus', difficulty: 1),
      WordWithDifficulty('Pilote', difficulty: 1),

      // MÉTIERS TRANSPORT - Moyen
      WordWithDifficulty('Chauffeur de taxi', difficulty: 2),
      WordWithDifficulty('Conducteur de train', difficulty: 2),
      WordWithDifficulty('Hôtesse de l\'air', difficulty: 2),

      // MÉTIERS TRANSPORT - Difficile
      WordWithDifficulty('Contrôleur aérien', difficulty: 3),

      // MÉTIERS JURIDIQUE - Moyen
      WordWithDifficulty('Avocat', difficulty: 1),
      WordWithDifficulty('Juge', difficulty: 1),
      WordWithDifficulty('Commissaire de police', difficulty: 2),

      // MÉTIERS JURIDIQUE - Difficile
      WordWithDifficulty('Notaire', difficulty: 3),
      WordWithDifficulty('Huissier', difficulty: 3),
      WordWithDifficulty('Greffier', difficulty: 3),
      WordWithDifficulty('Magistrat', difficulty: 3),
      WordWithDifficulty('Procureur', difficulty: 3),

      // MÉTIERS CRÉATIFS - Moyen
      WordWithDifficulty('Architecte', difficulty: 2),
      WordWithDifficulty('Journaliste', difficulty: 2),
      WordWithDifficulty('Photographe', difficulty: 2),
      WordWithDifficulty('Designer', difficulty: 3),
      WordWithDifficulty('Graphiste', difficulty: 3),
      WordWithDifficulty('Musicien', difficulty: 1),
      WordWithDifficulty('Acteur', difficulty: 1),

      // MÉTIERS CRÉATIFS - Difficile
      WordWithDifficulty('Scénariste', difficulty: 3),
      WordWithDifficulty('Monteur', difficulty: 3),
      WordWithDifficulty('Ingénieur du son', difficulty: 3),
      WordWithDifficulty('Réalisateur', difficulty: 2),
      WordWithDifficulty('Illustrateur', difficulty: 3),

      // MÉTIERS TECH - Moyen
      WordWithDifficulty('Développeur', difficulty: 3),
      WordWithDifficulty('Informaticien', difficulty: 2),
      WordWithDifficulty('Webdesigner', difficulty: 3),

      // MÉTIERS TECH - Difficile
      WordWithDifficulty('Data scientist', difficulty: 3),
      WordWithDifficulty('Administrateur système', difficulty: 3),

      // MÉTIERS COMMERCE - Facile
      WordWithDifficulty('Vendeur', difficulty: 1),
      WordWithDifficulty('Caissier', difficulty: 1),

      // MÉTIERS COMMERCE - Moyen
      WordWithDifficulty('Comptable', difficulty: 2),
      WordWithDifficulty('Commercial', difficulty: 2),
      WordWithDifficulty('Agent immobilier', difficulty: 2),
      WordWithDifficulty('Banquier', difficulty: 1),

      // MÉTIERS COMMERCE - Difficile
      WordWithDifficulty('Expert-comptable', difficulty: 3),
      WordWithDifficulty('Commissaire aux comptes', difficulty: 3),
      WordWithDifficulty('Trader', difficulty: 3),

      // MÉTIERS AGRICULTURE - Moyen
      WordWithDifficulty('Agriculteur', difficulty: 1),
      WordWithDifficulty('Éleveur', difficulty: 2),
      WordWithDifficulty('Apiculteur', difficulty: 2),

      // MÉTIERS AGRICULTURE - Difficile
      WordWithDifficulty('Maraîcher', difficulty: 3),
      WordWithDifficulty('Viticulteur', difficulty: 3),
      WordWithDifficulty('Sylviculteur', difficulty: 3),

      // SPORTS COLLECTIFS - Facile
      WordWithDifficulty('Football', difficulty: 1),
      WordWithDifficulty('Basketball', difficulty: 1),
      WordWithDifficulty('Volleyball', difficulty: 1),
      WordWithDifficulty('Handball', difficulty: 1),
      WordWithDifficulty('Rugby', difficulty: 1),

      // SPORTS COLLECTIFS - Moyen
      WordWithDifficulty('Hockey', difficulty: 2),
      WordWithDifficulty('Baseball', difficulty: 2),
      WordWithDifficulty('Water-polo', difficulty: 2),

      // SPORTS COLLECTIFS - Difficile
      WordWithDifficulty('Football américain', difficulty: 3),
      WordWithDifficulty('Hockey sur glace', difficulty: 3),
      WordWithDifficulty('Cricket', difficulty: 3),
      WordWithDifficulty('Ultimate (frisbee)', difficulty: 3),

      // SPORTS RAQUETTE - Facile
      WordWithDifficulty('Tennis', difficulty: 1),
      WordWithDifficulty('Badminton', difficulty: 1),
      WordWithDifficulty('Tennis de table', difficulty: 1),

      // SPORTS RAQUETTE - Moyen
      WordWithDifficulty('Squash', difficulty: 2),
      WordWithDifficulty('Padel', difficulty: 2),

      // SPORTS COMBAT - Facile
      WordWithDifficulty('Boxe', difficulty: 1),
      WordWithDifficulty('Judo', difficulty: 1),
      WordWithDifficulty('Karaté', difficulty: 1),

      // SPORTS COMBAT - Moyen
      WordWithDifficulty('Taekwondo', difficulty: 2),
      WordWithDifficulty('Kung Fu', difficulty: 2),
      WordWithDifficulty('Krav Maga', difficulty: 3),
      WordWithDifficulty('MMA', difficulty: 2),

      // SPORTS COMBAT - Difficile
      WordWithDifficulty('Lutte gréco-romaine', difficulty: 3),
      WordWithDifficulty('Aïkido', difficulty: 3),
      WordWithDifficulty('Jiu-jitsu', difficulty: 3),

      // SPORTS AQUATIQUES - Facile
      WordWithDifficulty('Natation', difficulty: 1),
      WordWithDifficulty('Plongée', difficulty: 2),

      // SPORTS AQUATIQUES - Moyen
      WordWithDifficulty('Surf', difficulty: 1),
      WordWithDifficulty('Voile', difficulty: 2),
      WordWithDifficulty('Canoë-kayak', difficulty: 2),
      WordWithDifficulty('Aviron', difficulty: 2),

      // SPORTS AQUATIQUES - Difficile
      WordWithDifficulty('Wakeboard', difficulty: 3),
      WordWithDifficulty('Kitesurf', difficulty: 3),
      WordWithDifficulty('Planche à voile', difficulty: 3),

      // SPORTS INDIVIDUELS - Facile
      WordWithDifficulty('Cyclisme', difficulty: 1),
      WordWithDifficulty('Course à pied', difficulty: 1),
      WordWithDifficulty('Ski', difficulty: 1),
      WordWithDifficulty('Golf', difficulty: 1),
      WordWithDifficulty('Danse', difficulty: 1),

      // SPORTS INDIVIDUELS - Moyen
      WordWithDifficulty('Athlétisme', difficulty: 2),
      WordWithDifficulty('Gymnastique', difficulty: 2),
      WordWithDifficulty('Escalade', difficulty: 2),
      WordWithDifficulty('Équitation', difficulty: 2),
      WordWithDifficulty('Patinage', difficulty: 2),
      WordWithDifficulty('Skateboard', difficulty: 2),
      WordWithDifficulty('Roller', difficulty: 2),

      // SPORTS INDIVIDUELS - Difficile
      WordWithDifficulty('Triathlon', difficulty: 2),
      WordWithDifficulty('Pentathlon', difficulty: 2),
      WordWithDifficulty('Haltérophilie', difficulty: 2),
      WordWithDifficulty('Escrime', difficulty: 2),
      WordWithDifficulty('Tir à l\'arc', difficulty: 2),
      WordWithDifficulty('BMX', difficulty: 3),

      // SPORTS D'HIVER - Moyen
      WordWithDifficulty('Snowboard', difficulty: 2),
      WordWithDifficulty('Ski de fond', difficulty: 3),
      WordWithDifficulty('Luge', difficulty: 2),

      // SPORTS D'HIVER - Difficile
      WordWithDifficulty('Biathlon', difficulty: 2),
      WordWithDifficulty('Patinage artistique', difficulty: 2),
      WordWithDifficulty('Curling', difficulty: 2),
      WordWithDifficulty('Bobsleigh', difficulty: 3),
      WordWithDifficulty('Skeleton', difficulty: 3),
      WordWithDifficulty('Ski acrobatique', difficulty: 3),

      // SPORTS EXTRÊMES - Difficile
      WordWithDifficulty('Parachutisme', difficulty: 2),
      WordWithDifficulty('Saut à l\'élastique', difficulty: 3),
      WordWithDifficulty('Deltaplane', difficulty: 3),
      WordWithDifficulty('Parapente', difficulty: 3),
      WordWithDifficulty('Base jump', difficulty: 3),
    
  ],
);
