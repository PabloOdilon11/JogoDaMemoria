import 'dart:math';
import 'package:flutter/material.dart';

class ShuffleFlipGame extends StatefulWidget {
  @override
  _ShuffleFlipGameState createState() => _ShuffleFlipGameState();
}

class _ShuffleFlipGameState extends State<ShuffleFlipGame> with SingleTickerProviderStateMixin {
  final int numCards = 12;
  late List<Offset> positions;        // posições normais (grid)
  late List<Offset> shuffledPositions; // posições embaralhadas
  bool isShuffled = true;

  late AnimationController controller;

  List<bool> cardFaceUp = [];

  @override
  void initState() {
    super.initState();

    cardFaceUp = List.generate(numCards, (_) => false);

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // posições em grid (3 x 4)
    positions = List.generate(numCards, (index) {
      int row = index ~/ 4;
      int col = index % 4;
      return Offset(col * 90.0, row * 120.0);
    });

    // posições embaralhadas (aleatórias)
    shuffledPositions = List.generate(numCards, (index) {
      final random = Random();
      return Offset(random.nextDouble() * 300, random.nextDouble() * 400);
    });

    // inicia a animação para desfazer embaralhamento após 2s
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isShuffled = false;
      });
    });
  }

  void flipCard(int index) {
    setState(() {
      cardFaceUp[index] = !cardFaceUp[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shuffle & Flip Cards')),
      body: Center(
        child: SizedBox(
          width: 400,
          height: 500,
          child: Stack(
            children: List.generate(numCards, (index) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 700),
                left: isShuffled ? shuffledPositions[index].dx : positions[index].dx,
                top: isShuffled ? shuffledPositions[index].dy : positions[index].dy,
                child: GestureDetector(
                  onTap: () => flipCard(index),
                  child: FlipCardWidget(isFaceUp: cardFaceUp[index]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class FlipCardWidget extends StatefulWidget {
  final bool isFaceUp;
  const FlipCardWidget({Key? key, required this.isFaceUp}) : super(key: key);

  @override
  _FlipCardWidgetState createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    if (widget.isFaceUp) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isFaceUp != oldWidget.isFaceUp) {
      if (widget.isFaceUp) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * pi;
        final isFront = _animation.value <= 0.5;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isFront
              ? Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('❓', style: TextStyle(fontSize: 32))),
          )
              : Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(pi),
            child: Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('🦋', style: TextStyle(fontSize: 32))),
            ),
          ),
        );
      },
    );
  }
}
