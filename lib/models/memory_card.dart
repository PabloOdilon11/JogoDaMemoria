class MemoryCard {
  final String value;
  bool isFaceUp;
  bool isMatched;

  MemoryCard({
    required this.value,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}
