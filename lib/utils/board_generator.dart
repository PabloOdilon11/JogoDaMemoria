import '../models/card_model.dart';

class BoardGenerator {
  static List<CardModel> generateBoard(String difficulty) {
    int pairCount;

    switch (difficulty.toLowerCase()) {
      case 'fácil':
        pairCount = 3;
        break;
      case 'médio':
        pairCount = 4;
        break;
      case 'difícil':
        pairCount = 5;
        break;
      default:
        pairCount = 3; // fallback
    }

    final List<CardModel> cards = [];

    for (int i = 0; i < pairCount; i++) {
      // Usa i como ID único para o par
      cards.add(CardModel(id: i, isFaceUp: false, isMatched: false));
      cards.add(CardModel(id: i, isFaceUp: false, isMatched: false));
    }

    cards.shuffle();
    return cards;
  }
}
