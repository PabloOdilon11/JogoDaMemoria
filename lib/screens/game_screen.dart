import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/card_model.dart';
import '../models/ranking_manager.dart';
import '../utils/board_generator.dart';
import '../models/ai_player.dart';
import '../utils/players.dart';
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
  late List<CardModel> _board;
  List<int> _selectedIndices = [];
  bool _canTap = false;
  int _playerScore = 0;
  int _aiScore = 0;
  Timer? _timer;
  int _secondsElapsed = 0;
  late AIPlayer _aiPlayer;
  Player _currentPlayer = Player.human;
  late List<AnimationController> _flipControllers;
  late List<Animation<double>> _flipAnimations;
  late AnimationController _shuffleController;
  late Animation<double> _shuffleAnimation;
  final Random _random = Random();
  bool _surpriseUsed = false;

  int get _matchCount {
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
    _setupGame();
  }

  @override
  void dispose() {
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    _shuffleController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _setupGame() {
    _playerScore = 0;
    _aiScore = 0;
    _secondsElapsed = 0;
    _selectedIndices = [];
    _surpriseUsed = false;
    _board = BoardGenerator.generateBoard(widget.difficulty);
    _initializeAnimations();

    if (widget.mode == 'vs IA') {
      _aiPlayer = AIPlayer(difficulty: widget.difficulty);
      _currentPlayer = Player.human;
    } else {
      _currentPlayer = Player.human;
    }

    _startShuffle();
    _startTimer();
  }

  void _initializeAnimations() {
    _flipControllers = List.generate(
      _board.length,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _flipAnimations = _flipControllers
        .map((c) => Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: c, curve: Curves.linear)))
        .toList();
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shuffleAnimation =
        CurvedAnimation(parent: _shuffleController, curve: Curves.easeInOut);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsElapsed++);
    });
  }

  Future<void> _startShuffle() async {
    setState(() => _canTap = false);
    await _shuffleController.forward();
    await _shuffleController.reverse();
    setState(() => _canTap = true);
  }

  Future<void> _onCardTap(int index) async {
    if (widget.mode == 'vs IA' && _currentPlayer != Player.human) return;
    if (!_canTap || _board[index].isMatched || _board[index].isFaceUp) return;

    setState(() {
      _canTap = false;
      _board[index].isFaceUp = true;
      _flipControllers[index].forward();
      _selectedIndices.add(index);
      if (widget.mode == 'vs IA') {
        _aiPlayer.rememberCard(index, _board[index].id);
      }
    });

    if (_selectedIndices.length == _matchCount) {
      await Future.delayed(const Duration(milliseconds: 800));
      await _checkForMatch();
    } else {
      setState(() => _canTap = true);
    }
  }

  Future<void> _checkForMatch() async {
    final bool allMatch =
        _selectedIndices.map((i) => _board[i].id).toSet().length == 1;

    if (allMatch) {
      _handleMatch();
    } else {
      await _handleMismatch();
    }

    _selectedIndices.clear();

    if (_board.every((card) => card.isMatched)) {
      _timer?.cancel();
      await Future.delayed(const Duration(milliseconds: 500));
      await _finishGame();
      return;
    }

    bool turnContinues = allMatch;

    if (!turnContinues && widget.mode == 'vs IA') {
      _switchTurn();
    }

    setState(() => _canTap = true);

    if (widget.mode == 'vs IA' && _currentPlayer == Player.ai) {
      await _aiTurn();
    }
  }

  void _handleMatch() {
    setState(() {
      for (var i in _selectedIndices) {
        _board[i].isMatched = true;
      }
      if (widget.mode == 'vs IA') {
        if (_currentPlayer == Player.human) _playerScore += 10;
        else _aiScore += 10;
      } else {
        _playerScore += 10;
      }
    });

    if (widget.mode == 'vs IA') {
      _aiPlayer.forgetCards(_selectedIndices);
    }
    _showSnackBar('✅ Acertou!', Colors.greenAccent.shade400);
  }

  Future<void> _handleMismatch() async {
    for (var i in _selectedIndices) {
      _board[i].isFaceUp = false;
      await _flipControllers[i].reverse();
    }

    // **** CORREÇÃO APLICADA AQUI ****
    setState(() {
      if (widget.mode == 'vs IA') {
        // Aplica a penalidade ao jogador atual no modo vs IA
        if (_currentPlayer == Player.human) {
          _playerScore += _getErrorPenalty();
        } else {
          _aiScore += _getErrorPenalty();
        }
      } else {
        // Aplica a penalidade no modo Solo
        _playerScore += _getErrorPenalty();
      }
    });

    _showSnackBar('❌ Errou!', Colors.redAccent.shade400);
  }

  void _switchTurn() {
    setState(() {
      _currentPlayer =
      (_currentPlayer == Player.human) ? Player.ai : Player.human;
    });
  }

  Future<void> _aiTurn() async {
    if (widget.mode != 'vs IA' || _currentPlayer != Player.ai || !_canTap) {
      return;
    }

    setState(() => _canTap = false);
    print("--- TURNO DA IA (Dificuldade: ${widget.difficulty}) ---");

    await Future.delayed(const Duration(milliseconds: 1200));

    List<int> choices = _aiPlayer.chooseCards(_board, _matchCount);

    if (choices.isEmpty) {
      setState(() => _canTap = true);
      if (widget.mode == 'vs IA') _switchTurn();
      return;
    }

    for (final index in choices) {
      if (_board[index].isFaceUp) continue;
      setState(() {
        _board[index].isFaceUp = true;
        _selectedIndices.add(index);
        _aiPlayer.rememberCard(index, _board[index].id);
      });
      _flipControllers[index].forward();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    await Future.delayed(const Duration(milliseconds: 800));
    await _checkForMatch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.pressStart2p(fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          _buildScoreDisplay(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Tempo: $_secondsElapsed s',
                style: GoogleFonts.pressStart2p(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: widget.mode == 'vs IA' && _currentPlayer != Player.human,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade800,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent, width: 4),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.amberAccent.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 4),
                  ],
                ),
                child: SizedBox(
                  width: 400,
                  height: 600,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _board.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      return _buildAnimatedCard(_board[index], index);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!_surpriseUsed)
                ElevatedButton(
                  onPressed: _useSurpriseCard,
                  child: Text('🃏', style: GoogleFonts.pressStart2p(fontSize: 50)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (widget.mode == 'vs IA') {
      return 'Vez de: ${_currentPlayer == Player.human ? widget.playerName : 'IA'}';
    }
    return 'Jogador: ${widget.playerName}';
  }

  Widget _buildScoreDisplay() {
    if (widget.mode == 'vs IA') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: Text(
            '${widget.playerName}: $_playerScore | IA: $_aiScore',
            style: GoogleFonts.pressStart2p(fontSize: 12),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Text(
          'Pontos: $_playerScore',
          style: GoogleFonts.pressStart2p(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(CardModel card, int index) {
    final offsetX = (_random.nextDouble() * 10 - 5) * _shuffleAnimation.value;
    final offsetY = (_random.nextDouble() * 10 - 5) * _shuffleAnimation.value;
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: GestureDetector(
        onTap: () => _onCardTap(index),
        child: AnimatedBuilder(
          animation: _flipAnimations[index],
          builder: (context, child) {
            final animValue = _flipAnimations[index].value;
            final isUnderHalf = animValue <= 0.5;
            final angle = animValue * pi;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isUnderHalf ? _buildCardBack() : _buildCardFront(card),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset('assets/card_back2.png', fit: BoxFit.cover),
    );
  }

  Widget _buildCardFront(CardModel card) {
    return Container(
      decoration: BoxDecoration(
        color: card.isMatched
            ? Colors.greenAccent.shade400
            : Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withAlpha(180),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getEmojiForId(card.id),
          style: GoogleFonts.pressStart2p(
            fontSize: 28,
            shadows: const [Shadow(color: Colors.amberAccent, blurRadius: 10)],
          ),
        ),
      ),
    );
  }

  Future<void> _finishGame() async {
    final entry = RankingEntry(
      name: widget.playerName,
      mode: widget.mode,
      difficulty: widget.difficulty,
      score: _playerScore,
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
            Text('Pontuação final: $_playerScore',
                style: GoogleFonts.pressStart2p(color: Colors.white)),
            Text('Tempo: $_secondsElapsed segundos',
                style: GoogleFonts.pressStart2p(color: Colors.white)),
            const SizedBox(height: 12),
            if (isTop5)
              Text(
                '🏅 Você entrou no Top 5!',
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

  String _getEmojiForId(int id) {
    const emojis = [
      '🍎', '🐶', '🎲', '🚗', '🦋', '🌟', '🍕', '🎈', '⚽', '🚀',
      '🎵', '🐱', '💡', '🎮', '🍔', '🐻', '🎁', '🚌', '🍩', '🎤',
      '📚', '🍇', '🎯', '🛸',
    ];
    return emojis[id % emojis.length];
  }

  Future<void> _useSurpriseCard() async {
    if (_surpriseUsed) return;
    setState(() {
      _surpriseUsed = true;
    });

    final randomEffect = _random.nextInt(2); // 0 ou 1

    switch (randomEffect) {
      case 0:
        await _revealOnePair();
        _showSnackBar('🃏 Par revelado!', Colors.greenAccent.shade400);
        break;
      case 1:
        await _startShuffle();
        if(widget.mode == 'vs IA') {
          _aiPlayer.forgetCards(_board.map((c) => c.id).toList());
        }
        _showSnackBar('🔀 Tabuleiro embaralhado!', Colors.blueAccent.shade400);
        break;
    }
  }

  Future<void> _revealOnePair() async {
    final unmatchedPairs = <int, List<int>>{};

    for (int i = 0; i < _board.length; i++) {
      if (!_board[i].isMatched && !_board[i].isFaceUp) {
        unmatchedPairs.putIfAbsent(_board[i].id, () => []).add(i);
      }
    }

    final pairs = unmatchedPairs.entries
        .where((entry) => entry.value.length >= _matchCount)
        .toList();

    if (pairs.isNotEmpty) {
      final selectedPair =
      pairs[_random.nextInt(pairs.length)].value.take(_matchCount).toList();

      for (var i in selectedPair) {
        if(!_board[i].isFaceUp){
          await _flipControllers[i].forward();
          _board[i].isFaceUp = true;
        }
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      for (var i in selectedPair) {
        if(_board[i].isFaceUp && !_board[i].isMatched){
          await _flipControllers[i].reverse();
          _board[i].isFaceUp = false;
        }
      }
    }
  }
}
