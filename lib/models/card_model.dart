class CardModel {
  final int id; // usado para agrupar pares/trincas
  bool isFaceUp;
  bool isMatched;
  bool isSpecial;

  CardModel({
    required this.id,
    this.isFaceUp = false,
    this.isMatched = false,
    this.isSpecial = false,
  });
}
