import 'package:flutter/material.dart';
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
  bool canTap = false; // trava toque durante embaralhamento
  int score = 0;

  // Controle do tempo
  Timer? _timer;
  int _secondsElapsed = 0;

  // Controladores de animação para virar cartas
  late List<AnimationController> flipControllers;
  late List<Animation<double>> flipAnimations;

  // Controlador para animação de embaralhamento
  late AnimationController shuffleController;
  late Animation<double> shuffleAnimation;

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    board = BoardGenerator.generateBoard(widget.difficulty);

    // Cria controladores para cada carta
    flipControllers = List.generate(
      board.length,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    flipAnimations = flipControllers
        .map((controller) =>
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.linear,
        )))
        .toList();

    // Configura animação de embaralhar
    shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    shuffleAnimation = CurvedAnimation(
      parent: shuffleController,
      curve: Curves.easeInOut,
    );

    // Começa embaralhar e, depois, inicia o jogo (libera toque)
    _startShuffle();

    // Inicia o temporizador
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

  // Função para embaralhar visualmente (animação simples de translação)
  Future<void> _startShuffle() async {
    canTap = false;
    await shuffleController.forward();
    await shuffleController.reverse();
    canTap = true;
    setState(() {}); // atualiza para liberar toques
  }

  Future<void> _onCardTap(int index) async {
    if (!canTap || board[index].isMatched) return;

    if (flipControllers[index].isAnimating) return; // previne toques enquanto vira

    if (board[index].isFaceUp) return;

    // Virar carta animada
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
        // Match
        setState(() {
          board[index].isMatched = true;
          board[firstIndex!].isMatched = true;
          score += 10;
        });
        _showSnackBar('✅ Par encontrado!', Colors.green);
      } else {
        // Não bateu, vira de volta as duas cartas
        await Future.delayed(const Duration(milliseconds: 300));

        await flipControllers[index].reverse();
        await flipControllers[firstIndex!].reverse();

        setState(() {
          board[index].isFaceUp = false;
          board[firstIndex!].isFaceUp = false;
          score += _getErrorPenalty();
        });
        _showSnackBar('❌ Errou o par', Colors.redAccent);
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
      content: Text(message, style: const TextStyle(fontSize: 16)),
      backgroundColor: color,
      duration: const Duration(milliseconds: 700),
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

    final topPlayers = await RankingManager.getRanking(); // Troque aqui
    final isTop5 = topPlayers.take(5).any((e) =>
    e.name == entry.name &&
        e.score == entry.score &&
        e.difficulty == entry.difficulty &&
        e.mode == entry.mode);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Fim de jogo!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pontuação final: $score'),
            Text('Tempo: $_secondsElapsed segundos'),
            const SizedBox(height: 12),
            if (isTop5)
              const Text(
                '🏅 Você entrou no Top 5!\nConfira no ranking depois. 🔥',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
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
            child: const Text('Voltar ao início'),
          ),
        ],
      ),
    );
  }

  // Widget da carta com animação de flip e movimento durante embaralhar
  Widget _buildCard(CardModel card, int index) {
    final faceUp = card.isFaceUp || card.isMatched;

    // Animação de embaralhar - deslocamento aleatório leve X e Y
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

            final angle = animValue * pi; // 0 a pi

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: Container(
                decoration: BoxDecoration(
                  color: card.isMatched
                      ? Colors.green
                      : (faceUp ? Colors.blueAccent : Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: faceUp
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    )
                  ]
                      : [],
                ),
                child: Center(
                  child: isUnderHalf
                      ? const Text(
                    '',
                    style: TextStyle(fontSize: 24),
                  )
                      : Text(
                    getEmojiForId(card.id),
                    style: const TextStyle(fontSize: 24),
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
      appBar: AppBar(
        title: Text('Jogador: ${widget.playerName}'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text('Pontos: $score', style: const TextStyle(fontSize: 16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Tempo: $_secondsElapsed s', style: const TextStyle(fontSize: 16)),
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
