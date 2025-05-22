import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/card_model.dart';
import '../utils/board_generator.dart';
import '../models/ranking_manager.dart';


import 'home_screen.dart';

import 'dart:async';
import 'dart:math';

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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late List<CardModel> board;
  CardModel? firstSelectedCard;
  int? firstIndex;
  bool canTap = false;
  int score = 0;

  Timer? _timer;
  int _secondsElapsed = 0;

  late List<AnimationController> flipControllers;
  late List<Animation<double>> flipAnimations;

  late AnimationController shuffleController;
  late Animation<double> shuffleAnimation;

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    board = BoardGenerator.generateBoard(widget.difficulty);

    flipControllers = List.generate(
      board.length,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    flipAnimations = flipControllers
        .map((controller) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ),
    ))
        .toList();

    shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    shuffleAnimation = CurvedAnimation(
      parent: shuffleController,
      curve: Curves.easeInOut,
    );

    _startShuffle();
    _startTimer();
  }

  @override
  void dispose() {
    for (var controller in flipControllers) {
      controller.dispose();
    }
    shuffleController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  Future<void> _startShuffle() async {
    canTap = false;
    await shuffleController.forward();
    await shuffleController.reverse();
    canTap = true;
    setState(() {});
  }

  Future<void> _onCardTap(int index) async {
    if (!canTap || board[index].isMatched) return;
    if (flipControllers[index].isAnimating) return;
    if (board[index].isFaceUp) return;

    await flipControllers[index].forward();
    setState(() {
      board[index].isFaceUp = true;
    });

    if (firstSelectedCard == null) {
      firstSelectedCard = board[index];
      firstIndex = index;
    } else {
      canTap = false;
      await Future.delayed(const Duration(milliseconds: 800));

      if (firstSelectedCard!.id == board[index].id) {
        setState(() {
          board[index].isMatched = true;
          board[firstIndex!].isMatched = true;
          score += 10;
        });
        _showSnackBar('✅ Par encontrado!', Colors.greenAccent.shade400);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        await flipControllers[index].reverse();
        await flipControllers[firstIndex!].reverse();

        setState(() {
          board[index].isFaceUp = false;
          board[firstIndex!].isFaceUp = false;
          score += _getErrorPenalty();
        });
        _showSnackBar('❌ Errou o par', Colors.redAccent.shade400);
      }

      firstSelectedCard = null;
      firstIndex = null;
      canTap = true;

      if (board.every((card) => card.isMatched)) {
        _timer?.cancel();
        await Future.delayed(const Duration(milliseconds: 500));
        await _finishGame();
      }
    }
  }

  int _getErrorPenalty() {
    switch (widget.difficulty.toLowerCase()) {
      case 'médio':
        return -2;
      case 'difícil':
        return -5;
      case 'fácil':
      default:
        return 0;
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
        style: GoogleFonts.pressStart2p(fontSize: 14, color: Colors.black),
      ),
      backgroundColor: color,
      duration: const Duration(milliseconds: 700),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  Future<void> _finishGame() async {
    final entry = RankingEntry(
      name: widget.playerName,
      mode: widget.mode,
      difficulty: widget.difficulty,
      score: score,
      dateTime: DateTime.now(),
      timeElapsed: _secondsElapsed,
    );

    await RankingManager.saveRanking(entry);

    final topPlayers = await RankingManager.getRanking();
    final isTop5 = topPlayers.take(5).any((e) =>
    e.name == entry.name &&
        e.score == entry.score &&
        e.difficulty == entry.difficulty &&
        e.mode == entry.mode);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        title: Text(
          '🎉 Fim de jogo!',
          style: GoogleFonts.pressStart2p(
            color: Colors.amberAccent,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pontuação final: $score',
                style: GoogleFonts.pressStart2p(color: Colors.white)),
            Text('Tempo: $_secondsElapsed segundos',
                style: GoogleFonts.pressStart2p(color: Colors.white)),
            const SizedBox(height: 12),
            if (isTop5)
              Text(
                '🏅 Você entrou no Top 5!\nConfira no ranking depois. 🔥',
                textAlign: TextAlign.center,
                style: GoogleFonts.pressStart2p(
                    color: Colors.amberAccent, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
              );
            },
            child: Text(
              'Voltar ao início',
              style: GoogleFonts.pressStart2p(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(CardModel card, int index) {

    final offsetX = (random.nextDouble() * 10 - 5) * shuffleAnimation.value;
    final offsetY = (random.nextDouble() * 10 - 5) * shuffleAnimation.value;

    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: GestureDetector(
        onTap: () => _onCardTap(index),
        child: AnimatedBuilder(
          animation: flipAnimations[index],
          builder: (context, child) {
            final animValue = flipAnimations[index].value;
            final isUnderHalf = animValue <= 0.5;
            final angle = animValue * pi;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isUnderHalf
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/card_back2.png',
                    fit: BoxFit.cover,
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: card.isMatched
                        ? Colors.greenAccent.shade400
                        : Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withAlpha((0.7 * 255).round()),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),

                    ],
                  ),
                  child: Center(
                    child: Text(
                      getEmojiForId(card.id),
                      style: GoogleFonts.pressStart2p(
                        fontSize: 28,
                        shadows: const [
                          Shadow(
                            color: Colors.amberAccent,
                            blurRadius: 10,
                            offset: Offset(0, 0),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String getEmojiForId(int id) {
    const emojis = [
      '🍎', '🐶', '🎲', '🚗', '🦋', '🌟', '🍕', '🎈',
      '⚽', '🚀', '🎵', '🐱', '🌈', '💡', '🎮',
    ];
    return emojis[id % emojis.length];
  }

  int getCrossAxisCount() {
    switch (widget.difficulty.toLowerCase()) {
      case 'fácil':
        return 3;
      case 'médio':
        return 4;
      case 'difícil':
        return 5;
      default:
        return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: Text(
          'Jogador: ${widget.playerName}',
          style: GoogleFonts.pressStart2p(),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Pontos: $score',
                style: GoogleFonts.pressStart2p(fontSize: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Tempo: $_secondsElapsed s',
                style: GoogleFonts.pressStart2p(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: board.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getCrossAxisCount(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          return _buildCard(board[index], index);
        },
      ),
    );
  }
}
