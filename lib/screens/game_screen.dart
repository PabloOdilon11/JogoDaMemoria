import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/card_model.dart';
import '../models/ranking_manager.dart';
import '../utils/board_generator.dart';
import 'home_screen.dart';

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
  List<int> selectedIndices = [];
  bool canTap = false;
  int score = 0;
  Timer? _timer;
  int _secondsElapsed = 0;
  bool surpriseUsed = false;

  late List<AnimationController> flipControllers;
  late List<Animation<double>> flipAnimations;

  late AnimationController shuffleController;
  late Animation<double> shuffleAnimation;

  final Random random = Random();

  int get matchCount {
    switch (widget.difficulty.toLowerCase()) {
      case 'médio':
        return 3;
      case 'difícil':
        return 4;
      case 'fácil':
      default:
        return 2;
    }
  }

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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    if (!canTap || board[index].isMatched || board[index].isFaceUp) return;

    await flipControllers[index].forward();
    board[index].isFaceUp = true;
    selectedIndices.add(index);

    if (selectedIndices.length == matchCount) {
      canTap = false;
      await Future.delayed(const Duration(milliseconds: 800));

      bool allMatch =
          selectedIndices.map((i) => board[i].id).toSet().length == 1;

      if (allMatch) {
        for (var i in selectedIndices) {
          board[i].isMatched = true;
        }
        score += 10;
        _showSnackBar('✅ Acertou!', Colors.greenAccent.shade400);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        for (var i in selectedIndices) {
          await flipControllers[i].reverse();
          board[i].isFaceUp = false;
        }
        score += _getErrorPenalty();
        _showSnackBar('❌ Errou!', Colors.redAccent.shade400);
      }

      selectedIndices.clear();
      canTap = true;

      if (board.every((card) => card.isMatched)) {
        _timer?.cancel();
        await Future.delayed(const Duration(milliseconds: 500));
        await _finishGame();
      }

      setState(() {});
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
                        color: Colors.deepPurpleAccent
                            .withAlpha((0.7 * 255).round()),
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
      '⚽', '🚀', '🎵', '🐱', '💡', '🎮', '🍔', '🐻',
      '🎁', '🚌', '🍩', '🎤', '📚', '🍇', '🎯', '🛸',
    ];
    return emojis[id % emojis.length];
  }

  Future<void> _useSurpriseCard() async {
    setState(() {
      surpriseUsed = true;
    });

    final randomEffect = random.nextInt(3);

    switch (randomEffect) {
      case 0:
        await _revealOnePair();
        _showSnackBar('🃏 Par revelado!', Colors.greenAccent.shade400);
        break;
      case 1:
        await _startShuffle();
        _showSnackBar('🔀 Tabuleiro embaralhado!', Colors.blueAccent.shade400);
        break;
      case 2:
        await _freezeTime();
        _showSnackBar('❄️ Tempo congelado por 7s!', Colors.cyanAccent.shade400);
        break;
    }
  }

  Future<void> _revealOnePair() async {
    final unmatchedPairs = <int, List<int>>{};

    for (int i = 0; i < board.length; i++) {
      if (!board[i].isMatched && !board[i].isFaceUp) {
        unmatchedPairs.putIfAbsent(board[i].id, () => []).add(i);
      }
    }

    final pairs = unmatchedPairs.entries
        .where((entry) => entry.value.length >= matchCount)
        .toList();

    if (pairs.isNotEmpty) {
      final selectedPair =
      pairs[random.nextInt(pairs.length)].value.take(matchCount).toList();

      for (var i in selectedPair) {
        await flipControllers[i].forward();
        board[i].isFaceUp = true;
      }

      selectedIndices.addAll(selectedPair);
    }
  }

  Future<void> _freezeTime() async {
    _timer?.cancel();
    await Future.delayed(const Duration(seconds: 7));
    _startTimer();
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amberAccent,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amberAccent.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: SizedBox(
                width: 400,
                height: 600,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: board.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    return _buildCard(board[index], index);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!surpriseUsed)
              ElevatedButton(
                onPressed: _useSurpriseCard,
                child: Text(
                  '🃏',
                  style: GoogleFonts.pressStart2p(fontSize: 50),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}