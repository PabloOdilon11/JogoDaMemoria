import '../models/card_model.dart';
import 'dart:math';

class BoardGenerator {
  static List<CardModel> generateBoard(String difficulty) {
    int groupSize;
    switch (difficulty) {
      case 'Médio':
        groupSize = 3;
        break;
      case 'Difícil':
        groupSize = 4;
        break;
      case 'Extremo':
        return _generateMixedBoard();
      default:
        groupSize = 2;
    }

    const int totalCards = 24;
    int totalGroups = totalCards ~/ groupSize;
    List<CardModel> cards = [];

    int idCounter = 0;
    for (int i = 0; i < totalGroups; i++) {
      for (int j = 0; j < groupSize; j++) {
        cards.add(CardModel(id: idCounter));
      }
      idCounter++;
    }

    cards.shuffle();
    return cards;
  }

  static List<CardModel> _generateMixedBoard() {
    List<CardModel> cards = [];
    const int totalCards = 24;
    List<int> groupSizes = [2, 3, 4];
    int idCounter = 0;
    int remaining = totalCards;

    final rand = Random();
    while (remaining > 0) {
      int size = groupSizes[rand.nextInt(groupSizes.length)];
      if (size > remaining) size = remaining;
      for (int i = 0; i < size; i++) {
        cards.add(CardModel(id: idCounter));
      }
      idCounter++;
      remaining -= size;
    }

    cards.shuffle();
    return cards;
  }
}
