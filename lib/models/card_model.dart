class CardModel {
  final int id;
  bool isFaceUp;
  bool isMatched;

  CardModel({
    required this.id,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}
