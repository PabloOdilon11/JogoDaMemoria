import 'dart:math';
import 'package:flutter/material.dart';

class ShuffleFlipGame extends StatefulWidget {
  @override
  _ShuffleFlipGameState createState() => _ShuffleFlipGameState();
}

class _ShuffleFlipGameState extends State<ShuffleFlipGame> with SingleTickerProviderStateMixin {
  final int numCards = 18; // múltiplo de 6 para 6 colunas
  late List<Offset> positions;
  late List<Offset> shuffledPositions;
  bool isShuffled = true;

  late AnimationController controller;

  List<bool> cardFaceUp = [];

  final double cardWidth = 60;
  final double cardHeight = 80;
  final double spacing = 10;

  @override
  void initState() {
    super.initState();

    cardFaceUp = List.generate(numCards, (_) => false);

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Grid: 6 colunas
    positions = List.generate(numCards, (index) {
      int row = index ~/ 6;
      int col = index % 6;
      return Offset(
        col * (cardWidth + spacing),
        row * (cardHeight + spacing),
      );
    });

    shuffledPositions = List.generate(numCards, (index) {
      final random = Random();
      return Offset(random.nextDouble() * 300, random.nextDouble() * 400);
    });

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text('Shuffle & Flip Game'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: (cardWidth + spacing) * 6 - spacing + 32, // 6 colunas + padding
          height: (cardHeight + spacing) * ((numCards / 6).ceil()) - spacing + 32,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: List.generate(numCards, (index) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 700),
                left: isShuffled ? shuffledPositions[index].dx : positions[index].dx,
                top: isShuffled ? shuffledPositions[index].dy : positions[index].dy,
                child: GestureDetector(
                  onTap: () => flipCard(index),
                  child: FlipCardWidget(
                    isFaceUp: cardFaceUp[index],
                    width: cardWidth,
                    height: cardHeight,
                  ),
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
  final double width;
  final double height;

  const FlipCardWidget({
    Key? key,
    required this.isFaceUp,
    required this.width,
    required this.height,
  }) : super(key: key);

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
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(child: Text('❓', style: TextStyle(fontSize: 24))),
          )
              : Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(pi),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amberAccent, width: 2),
              ),
              child: const Center(child: Text('🦋', style: TextStyle(fontSize: 24))),
            ),
          ),
        );
      },
    );
  }
}
