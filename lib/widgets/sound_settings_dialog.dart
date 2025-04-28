// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class SoundSettingsDialog extends StatefulWidget {
  const SoundSettingsDialog({super.key});

  @override
  State<SoundSettingsDialog> createState() => _SoundSettingsDialogState();
}

class _SoundSettingsDialogState extends State<SoundSettingsDialog> {
  final SoundService _soundService = SoundService();
  bool _musicEnabled = true;
  bool _effectsEnabled = true;
  bool _uiEnabled = true;
  bool _alarmEnabled = true;
  double _musicVolume = 0.5;
  double _effectsVolume = 0.7;
  double _uiVolume = 0.5;
  double _alarmVolume = 0.8;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _soundService.initialize();
    setState(() {
      _musicEnabled = _soundService.isMusicEnabled;
      _effectsEnabled = _soundService.isEffectsEnabled;
      _uiEnabled = _soundService.isUIEnabled;
      _alarmEnabled = _soundService.isAlarmEnabled;
      _musicVolume = _soundService.musicVolume;
      _effectsVolume = _soundService.effectsVolume;
      _uiVolume = _soundService.uiVolume;
      _alarmVolume = _soundService.alarmVolume;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _soundService.setMusicEnabled(_musicEnabled);
    await _soundService.setEffectsEnabled(_effectsEnabled);
    await _soundService.setUIEnabled(_uiEnabled);
    await _soundService.setAlarmEnabled(_alarmEnabled);
    await _soundService.setMusicVolume(_musicVolume);
    await _soundService.setEffectsVolume(_effectsVolume);
    await _soundService.setUIVolume(_uiVolume);
    await _soundService.setAlarmVolume(_alarmVolume);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.black.withOpacity(0.92),
      child: _loading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_up, color: Colors.blue, size: 28),
                      const SizedBox(width: 10),
                      Text('Sound Settings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSwitchSlider(
                    label: 'Music',
                    enabled: _musicEnabled,
                    onToggle: (v) => setState(() => _musicEnabled = v),
                    volume: _musicVolume,
                    onVolume: (v) => setState(() => _musicVolume = v),
                    onTest: () => _soundService.playMainTheme(),
                  ),
                  const SizedBox(height: 10),
                  _buildSwitchSlider(
                    label: 'Effects',
                    enabled: _effectsEnabled,
                    onToggle: (v) => setState(() => _effectsEnabled = v),
                    volume: _effectsVolume,
                    onVolume: (v) => setState(() => _effectsVolume = v),
                    onTest: () => _soundService.playPieceDrop(),
                  ),
                  const SizedBox(height: 10),
                  _buildSwitchSlider(
                    label: 'UI',
                    enabled: _uiEnabled,
                    onToggle: (v) => setState(() => _uiEnabled = v),
                    volume: _uiVolume,
                    onVolume: (v) => setState(() => _uiVolume = v),
                    onTest: () => _soundService.playButtonClick(),
                  ),
                  const SizedBox(height: 10),
                  _buildSwitchSlider(
                    label: 'Alarm',
                    enabled: _alarmEnabled,
                    onToggle: (v) => setState(() => _alarmEnabled = v),
                    volume: _alarmVolume,
                    onVolume: (v) => setState(() => _alarmVolume = v),
                    onTest: () => _soundService.playTimerTick(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await _saveSettings();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Save',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchSlider({
    required String label,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required double volume,
    required ValueChanged<double> onVolume,
    required VoidCallback onTest,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const IconButton(
            icon: Icon(Icons.volume_down, color: Colors.white38, size: 20),
            onPressed: null,
            splashRadius: 18,
          ),
          Expanded(
            child: Slider(
              value: volume,
              onChanged: enabled ? onVolume : null,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: Colors.blue,
              inactiveColor: Colors.white12,
            ),
          ),
          const IconButton(
            icon: Icon(Icons.volume_up, color: Colors.white38, size: 20),
            onPressed: null,
            splashRadius: 18,
          ),
          const SizedBox(width: 8),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeColor: Colors.blue,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white70),
            onPressed: enabled ? onTest : null,
            tooltip: 'Test',
            splashRadius: 18,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
