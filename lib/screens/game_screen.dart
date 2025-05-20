import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../utils/board_generator.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  final String mode;
  final String difficulty;

  const GameScreen({
    super.key,
    required this.playerName,
    required this.mode,
    required this.difficulty,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<CardModel> board;

  @override
  void initState() {
    super.initState();
    board = BoardGenerator.generateBoard(widget.difficulty);
  }

  void _onCardTap(int index) {
    setState(() {
      board[index].isFaceUp = !board[index].isFaceUp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jogador: ${widget.playerName}'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: board.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final card = board[index];
          return GestureDetector(
            onTap: () => _onCardTap(index),
            child: Container(
              color: card.isFaceUp ? Colors.blue : Colors.grey,
              child: Center(
                child: card.isFaceUp ? Text('${card.id}') : const Text(''),
              ),
            ),
          );
        },
      ),
    );
  }
}
