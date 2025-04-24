import 'package:flutter/material.dart';
import 'player_name_page.dart';

class GameModePage extends StatefulWidget {
  const GameModePage({super.key});

  @override
  State<GameModePage> createState() => _GameModePageState();
}

class _GameModePageState extends State<GameModePage> {
  bool isBotEnabled = false;
  String difficulty = 'Beginner';

  void _goToNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerNamePage(
          isBotEnabled: isBotEnabled,
          difficulty: difficulty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Game Mode'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Mode:', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 180,
                    child: DropdownButton<bool>(
                      value: isBotEnabled,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                      dropdownColor: Colors.grey[900],
                      items: const [
                        DropdownMenuItem(
                          value: false,
                          child: Row(
                            children: [
                              Icon(Icons.people, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Two Player'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: true,
                          child: Row(
                            children: [
                              Icon(Icons.smart_toy, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Vs Bot'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => isBotEnabled = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isBotEnabled)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Difficulty:', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 180,
                      child: DropdownButton<String>(
                        value: difficulty,
                        isExpanded: true,
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                        dropdownColor: Colors.grey[900],
                        items: [
                          DropdownMenuItem(
                            value: 'Beginner',
                            child: Row(
                              children: [
                                Icon(Icons.star_border, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Beginner'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Intermediate',
                            child: Row(
                              children: [
                                Icon(Icons.star_half, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Intermediate'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Professional',
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text('Professional'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => difficulty = value!),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _goToNext,
                  child: const Text('Next', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
