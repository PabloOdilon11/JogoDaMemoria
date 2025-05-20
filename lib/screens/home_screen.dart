import 'package:flutter/material.dart';
import 'game_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jogo da Memória')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Seu nome'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMode,
              items: modes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedMode = val!),
              decoration: const InputDecoration(labelText: 'Modo de Jogo'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              items: difficulties.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedDifficulty = val!),
              decoration: const InputDecoration(labelText: 'Nível de Dificuldade'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _startGame,
              child: const Text('Iniciar Jogo'),
            ),
          ],
        ),
      ),
    );
  }
}
