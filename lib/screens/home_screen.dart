import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_screen.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedMode = 'Competitivo';
  String _selectedDifficulty = 'Fácil';

  final List<String> modes = ['Competitivo', 'Cooperativo'];
  final List<String> difficulties = ['Fácil', 'Médio', 'Difícil', 'Extremo'];

  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          playerName: _nameController.text,
          mode: _selectedMode,
          difficulty: _selectedDifficulty,
        ),
      ),
    );
  }

  void _viewRanking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RankingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
        title: Text(
          '🎮 JOGO DA MEMÓRIA',
          style: GoogleFonts.pressStart2p(
            fontSize: 14,
            color: Colors.amberAccent,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              style: GoogleFonts.pressStart2p(color: Colors.amberAccent),
              decoration: InputDecoration(
                labelText: 'SEU NOME',
                labelStyle: GoogleFonts.pressStart2p(
                  color: Colors.purpleAccent,
                  fontSize: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurpleAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amberAccent, width: 2),
                ),
                filled: true,
                fillColor: Colors.deepPurple.shade900,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedMode,
              style: GoogleFonts.pressStart2p(color: Colors.amberAccent),
              dropdownColor: Colors.deepPurple.shade900,
              decoration: InputDecoration(
                labelText: 'MODO DE JOGO',
                labelStyle: GoogleFonts.pressStart2p(
                  color: Colors.purpleAccent,
                  fontSize: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurpleAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amberAccent, width: 2),
                ),
                filled: true,
                fillColor: Colors.deepPurple.shade900,
              ),
              items: modes
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.pressStart2p()),
                ),
              )
                  .toList(),
              onChanged: (val) => setState(() => _selectedMode = val!),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              style: GoogleFonts.pressStart2p(color: Colors.amberAccent),
              dropdownColor: Colors.deepPurple.shade900,
              decoration: InputDecoration(
                labelText: 'NÍVEL DE DIFICULDADE',
                labelStyle: GoogleFonts.pressStart2p(
                  color: Colors.purpleAccent,
                  fontSize: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurpleAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amberAccent, width: 2),
                ),
                filled: true,
                fillColor: Colors.deepPurple.shade900,
              ),
              items: difficulties
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.pressStart2p()),
                ),
              )
                  .toList(),
              onChanged: (val) => setState(() => _selectedDifficulty = val!),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: Colors.purpleAccent,
                elevation: 8,
              ),
              child: Text(
                'INICIAR JOGO',
                style: GoogleFonts.pressStart2p(
                  color: Colors.amberAccent,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _viewRanking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: Colors.amberAccent.shade400,
            elevation: 8,
          ),
          child: Text(
            'VER RANKING',
            style: GoogleFonts.pressStart2p(
              color: Colors.black87,
              fontSize: 12,
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}