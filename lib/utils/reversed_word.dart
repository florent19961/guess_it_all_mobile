import 'package:flutter/widgets.dart';

/// Affichage du malus « Mot à l'envers » (2-8) : la chaîne entière en
/// MAJUSCULES puis inversée par graphèmes (« Star Wars » → « SRAW RATS »).
///
/// Inverser par graphèmes (`characters`) et non par unités de code : un accent
/// combiné ou un emoji reste entier.
String reversedWordDisplay(String word) =>
    word.toUpperCase().characters.toList().reversed.join();
