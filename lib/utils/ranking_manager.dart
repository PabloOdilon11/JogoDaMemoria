import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RankingEntry {
  final String name;
  final String mode;
  final String difficulty;
  final int score;
  final DateTime dateTime;

  RankingEntry({
    required this.name,
    required this.mode,
    required this.difficulty,
    required this.score,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'mode': mode,
    'difficulty': difficulty,
    'score': score,
    'dateTime': dateTime.toIso8601String(),
  };

  factory RankingEntry.fromMap(Map<String, dynamic> map) => RankingEntry(
    name: map['name'],
    mode: map['mode'],
    difficulty: map['difficulty'],
    score: map['score'],
    dateTime: DateTime.parse(map['dateTime']),
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

  static Future<void> saveRanking(RankingEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_storageKey);
    final List<RankingEntry> entries =
    existing != null ? RankingEntry.fromJsonList(existing) : [];

    entries.add(entry);
    entries.sort((a, b) => b.score.compareTo(a.score));

    final top5 = entries.take(5).toList();
    await prefs.setString(_storageKey, RankingEntry.toJsonList(top5));
  }

  static Future<List<RankingEntry>> getRanking() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];
    return RankingEntry.fromJsonList(data);
  }
}
