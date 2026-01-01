import 'models.dart';
import 'categories/7eme_art.dart';
import 'categories/geographie.dart';
import 'categories/nature.dart';
import 'categories/metiers_sports.dart';
import 'categories/celebrites.dart';
import 'categories/noms_communs.dart';
import 'categories/univers_arcade.dart';
import 'categories/expressions.dart';
import 'categories/dictionnaire.dart';
import 'categories/musique.dart';
import 'categories/metro_parisien.dart';
import 'categories/marques.dart';
import 'categories/medecine.dart';

final Map<String, WordCategory> wordCategories = {
  '7eme_art': category7emeArt,
  'geographie': categoryGeographie,
  'nature': categoryNature,
  'metiers_sports': categoryMetiersSports,
  'celebrites': categoryCelebrites,
  'noms_communs': categoryNomsCommuns,
  'univers_arcade': categoryUniversArcade,
  'expressions': categoryExpressions,
  'dictionnaire': categoryDictionnaire,
  'musique': categoryMusique,
  'metro_parisien': categoryMetroParisien,
  'marques': categoryMarques,
  'medecine': categoryMedecine,
};
