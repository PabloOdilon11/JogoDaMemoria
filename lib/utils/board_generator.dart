import '../models/card_model.dart';
import 'dart:math';

class BoardGenerator {
  static List<CardModel> generateBoard(String difficulty) {
    final List<int> uniqueIds = [];
    final random = Random();

    int groupSize;
    int totalCards;

    switch (difficulty.toLowerCase()) {
      case 'médio':
        groupSize = 3;
        totalCards = 24;
        break;
      case 'difícil':
        groupSize = 4;
        totalCards = 24;
        break;
      case 'fácil':
      default:
        groupSize = 2;
        totalCards = 24;
        break;
    }

    final numGroups = totalCards ~/ groupSize;

    while (uniqueIds.length < numGroups) {
      int id = random.nextInt(1000);
      if (!uniqueIds.contains(id)) {
        uniqueIds.add(id);
      }
    }

    List<CardModel> board = [];
    for (int id in uniqueIds) {
      board.addAll(List.generate(groupSize, (_) => CardModel(id: id)));
    }

    board.shuffle();
    return board;
  }
}
