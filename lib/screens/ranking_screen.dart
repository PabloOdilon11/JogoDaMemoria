import 'package:flutter/material.dart';
import '../models/ranking_manager.dart';
import '../ranking_manager.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<RankingEntry> ranking = [];

  @override
  void initState() {
    super.initState();
    loadRanking();
  }

  Future<void> loadRanking() async {
    final result = await RankingManager.getRanking();
    setState(() {
      ranking = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking dos Jogadores'),
        centerTitle: true,
      ),
      body: ranking.isEmpty
          ? const Center(child: Text('Nenhum ranking disponível ainda.'))
          : ListView.builder(
        itemCount: ranking.length,
        itemBuilder: (context, index) {
          final entry = ranking[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(entry.name),
            subtitle: Text(
              'Modo: ${entry.mode} | Dificuldade: ${entry.difficulty}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pontos: ${entry.score}'),
                Text(
                  '${entry.dateTime.day}/${entry.dateTime.month} ${entry.dateTime.hour}:${entry.dateTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
