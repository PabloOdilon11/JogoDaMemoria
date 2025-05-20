import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RankingEntry {
  final String name;
  final String mode;
  final String difficulty;
  final int score;
  final DateTime dateTime;
  final int timeElapsed; // tempo em segundos, por exemplo

  RankingEntry({
    required this.name,
    required this.mode,
    required this.difficulty,
    required this.score,
    required this.dateTime,
    required this.timeElapsed,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'mode': mode,
    'difficulty': difficulty,
    'score': score,
    'dateTime': dateTime.toIso8601String(),
    'timeElapsed': timeElapsed,
  };

  factory RankingEntry.fromMap(Map<String, dynamic> map) => RankingEntry(
    name: map['name'],
    mode: map['mode'],
    difficulty: map['difficulty'],
    score: map['score'],
    dateTime: DateTime.parse(map['dateTime']),
    timeElapsed: map['timeElapsed'] ?? 0,
  );

  static List<RankingEntry> fromJsonList(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => RankingEntry.fromMap(e)).toList();
  }

  static String toJsonList(List<RankingEntry> entries) {
    final list = entries.map((e) => e.toMap()).toList();
    return jsonEncode(list);
  }
}

class RankingManager {
  static const String _storageKey = 'ranking';

  // Salva a entrada no ranking e mantém só os top 5
  static Future<void> saveRanking(RankingEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_storageKey);

    final List<RankingEntry> entries =
    existing != null ? RankingEntry.fromJsonList(existing) : [];

    entries.add(entry);
    // Ordena pelo score desc, e se empatar, pelo menor tempoElapsed (melhor quem fez mais rápido)
    entries.sort((a, b) {
      int cmp = b.score.compareTo(a.score);
      if (cmp == 0) {
        return a.timeElapsed.compareTo(b.timeElapsed);
      }
      return cmp;
    });

    final top5 = entries.take(5).toList();
    await prefs.setString(_storageKey, RankingEntry.toJsonList(top5));
  }

  // Recupera o ranking do dispositivo
  static Future<List<RankingEntry>> getRanking() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];
    return RankingEntry.fromJsonList(data);
  }

  // Limpa o ranking
  static Future<void> clearRanking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static loadRanking() {}
}
