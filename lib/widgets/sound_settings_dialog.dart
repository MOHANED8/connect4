// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_import, unused_local_variable

import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../utils/styles.dart';

class SoundSettingsDialog extends StatefulWidget {
  const SoundSettingsDialog({super.key});

  @override
  State<SoundSettingsDialog> createState() => _SoundSettingsDialogState();
}

class _SoundSettingsDialogState extends State<SoundSettingsDialog> {
  final SoundService _soundService = SoundService();
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;
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
      _musicVolume = _soundService.musicVolume;
      // SFX: combine effects, UI, and alarm
      _sfxEnabled = _soundService.isEffectsEnabled ||
          _soundService.isUIEnabled ||
          _soundService.isAlarmEnabled;
      _sfxVolume = (_soundService.effectsVolume +
              _soundService.uiVolume +
              _soundService.alarmVolume) /
          3.0;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _soundService.setMusicEnabled(_musicEnabled);
    await _soundService.setMusicVolume(_musicVolume);
    // SFX applies to all non-music
    await _soundService.setEffectsEnabled(_sfxEnabled);
    await _soundService.setUIEnabled(_sfxEnabled);
    await _soundService.setAlarmEnabled(_sfxEnabled);
    await _soundService.setEffectsVolume(_sfxVolume);
    await _soundService.setUIVolume(_sfxVolume);
    await _soundService.setAlarmVolume(_sfxVolume);
  }

  Widget _buildVolumeRow({
    required String label,
    required double volume,
    required ValueChanged<double> onVolume,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: volume,
              onChanged: onVolume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              activeColor: Colors.blue,
              inactiveColor: Colors.blue.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 12),
          Text('${(volume * 100).round()}%',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.black,
      child: _loading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Sound Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildVolumeRow(
                    label: 'MUSIC',
                    volume: _musicVolume,
                    onVolume: (v) => setState(() => _musicVolume = v),
                    icon: Icons.music_note,
                    iconColor: Colors.amber,
                  ),
                  _buildVolumeRow(
                    label: 'SFX',
                    volume: _sfxVolume,
                    onVolume: (v) => setState(() => _sfxVolume = v),
                    icon: Icons.volume_up,
                    iconColor: Colors.amber,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          _soundService.playButtonClick();
                          await _saveSettings();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
}
