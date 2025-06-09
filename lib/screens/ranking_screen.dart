import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ranking_manager.dart';

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
        title: Text(
          '🏆 RANKING RETRÔ',
          style: GoogleFonts.pressStart2p(
            fontSize: 14,
            color: Colors.amberAccent,
          ),
        ),
      ),
      body: ranking.isEmpty
          ? Center(
        child: Text(
          'Nenhum ranking disponível ainda.',
          style: GoogleFonts.pressStart2p(
            fontSize: 10,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        itemCount: ranking.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final entry = ranking[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.6),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  '#${index + 1}',
                  style: GoogleFonts.pressStart2p(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 10,
                          color: Colors.yellowAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Modo: ${entry.mode} | Dificuldade: ${entry.difficulty}',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 7,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Pontos: ${entry.score}',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 8,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    Text(
                      '${entry.dateTime.day}/${entry.dateTime.month} ${entry.dateTime.hour}:${entry.dateTime.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 6,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}