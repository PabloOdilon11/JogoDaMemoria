import 'dart:math';
import 'card_model.dart';

class AIPlayer {
  final String difficulty;
  // A memória agora é uma lista para funcionar como uma fila (FIFO).
  final List<MapEntry<int, int>> _memoryQueue = [];
  final Random _random = Random();

  AIPlayer({required this.difficulty});

  // Define a capacidade da memória com base na dificuldade.
  int get _memoryCapacity {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
        return 4; // Lembra as últimas 2 jogadas do humano
      case 'médio':
        return 12;
      case 'difícil':
      default:
        return 1000; // Memória "perfeita"
    }
  }

  /// A IA "vê" uma carta e a guarda na memória.
  void rememberCard(int index, int cardId) {
    // Remove se a carta já estava na memória para adicioná-la como a mais recente.
    _memoryQueue.removeWhere((entry) => entry.key == index);
    _memoryQueue.add(MapEntry(index, cardId));

    // Se a memória exceder a capacidade, remove a mais antiga.
    if (_memoryQueue.length > _memoryCapacity) {
      _memoryQueue.removeAt(0);
    }
  }

  /// A IA "esquece" as cartas que já formaram um conjunto.
  void forgetCards(List<int> indices) {
    _memoryQueue.removeWhere((entry) => indices.contains(entry.key));
  }

  /// Lógica principal de decisão da IA.
  List<int> chooseCards(List<CardModel> board, int matchCount) {
    List<int> availableCardIndices = [];
    for (int i = 0; i < board.length; i++) {
      if (!board[i].isMatched && !board[i].isFaceUp) {
        availableCardIndices.add(i);
      }
    }

    if (availableCardIndices.length < matchCount) {
      return [];
    }

    // Converte a fila de memória para um mapa para a lógica de busca.
    final Map<int, int> currentMemory = Map.fromEntries(_memoryQueue);

    // --- ESTRATÉGIA 1: Procurar por um conjunto garantido na memória ---
    var groupedByValue = <int, List<int>>{};
    currentMemory.forEach((index, id) {
      if (availableCardIndices.contains(index)) {
        groupedByValue.putIfAbsent(id, () => []).add(index);
      }
    });

    for (var entry in groupedByValue.entries) {
      if (entry.value.length >= matchCount) {
        print(
            "IA [Estratégia 1]: Encontrei um conjunto garantido! -> ID ${entry.key}");
        return entry.value.take(matchCount).toList();
      }
    }

    // --- ESTRATÉGIA 2: Virar cartas conhecidas + aleatórias ---
    List<int> knownAndAvailable = currentMemory.keys
        .where((index) => availableCardIndices.contains(index))
        .toList();
    knownAndAvailable.shuffle(_random);

    List<int> choices = List.from(knownAndAvailable);
    List<int> unknownAndAvailable = availableCardIndices
        .where((index) => !currentMemory.containsKey(index))
        .toList();
    unknownAndAvailable.shuffle(_random);

    int i = 0;
    while (choices.length < matchCount && i < unknownAndAvailable.length) {
      choices.add(unknownAndAvailable[i]);
      i++;
    }

    if (choices.length >= matchCount) {
      print("IA [Estratégia 2]: Jogada semi-aleatória.");
      return choices.take(matchCount).toList();
    }

    // --- ESTRATÉGIA 3: Jogada totalmente aleatória (Fallback) ---
    print("IA [Estratégia 3]: Jogada totalmente aleatória.");
    availableCardIndices.shuffle(_random);
    return availableCardIndices.take(matchCount).toList();
  }
}
