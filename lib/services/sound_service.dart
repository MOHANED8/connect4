// ignore_for_file: unnecessary_import

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Audio players
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _effectsPlayer = AudioPlayer();
  final AudioPlayer _uiPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();

  // Sound state
  bool _isInitialized = false;
  bool _isMusicEnabled = true;
  bool _isEffectsEnabled = true;
  bool _isUIEnabled = true;
  bool _isAlarmEnabled = true;
  double _musicVolume = 0.5;
  double _effectsVolume = 0.7;
  double _uiVolume = 0.5;
  double _alarmVolume = 0.8;
  bool _isMusicPlaying = false;
  String? _currentMusic;

  // Sound cache
  final Map<String, Source> _soundCache = {};
  bool _isPreloading = false;

  // Settings keys
  static const String _musicVolumeKey = 'musicVolume';
  static const String _effectsVolumeKey = 'effectsVolume';
  static const String _uiVolumeKey = 'uiVolume';
  static const String _alarmVolumeKey = 'alarmVolume';
  static const String _musicEnabledKey = 'isMusicEnabled';
  static const String _effectsEnabledKey = 'isEffectsEnabled';
  static const String _uiEnabledKey = 'isUIEnabled';
  static const String _alarmEnabledKey = 'isAlarmEnabled';

  // Constants
  static const double _minVolume = 0.0;
  static const double _maxVolume = 1.0;

  static BuildContext? _snackBarContext;
  static void setSnackBarContext(BuildContext context) {
    _snackBarContext = context;
  }

  static void showErrorSnackBar(String message) {
    if (_snackBarContext != null) {
      ScaffoldMessenger.of(_snackBarContext!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isMusicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
      _isEffectsEnabled = prefs.getBool(_effectsEnabledKey) ?? true;
      _isUIEnabled = prefs.getBool(_uiEnabledKey) ?? true;
      _isAlarmEnabled = prefs.getBool(_alarmEnabledKey) ?? true;
      _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.5;
      _effectsVolume = prefs.getDouble(_effectsVolumeKey) ?? 0.7;
      _uiVolume = prefs.getDouble(_uiVolumeKey) ?? 0.5;
      _alarmVolume = prefs.getDouble(_alarmVolumeKey) ?? 0.8;

      // Set initial volumes
      await _musicPlayer.setVolume(_musicVolume);
      await _effectsPlayer.setVolume(_effectsVolume);
      await _uiPlayer.setVolume(_uiVolume);
      await _alarmPlayer.setVolume(_alarmVolume);

      // Set up event listeners
      _musicPlayer.onPlayerStateChanged.listen((state) {
        _isMusicPlaying = state == PlayerState.playing;
      });

      // Preload sounds
      await _preloadSounds();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing sound service: $e');
      _resetToDefaults();
    }
  }

  Future<void> _preloadSounds() async {
    if (_isPreloading) return;
    _isPreloading = true;

    try {
      final sounds = [
        'sounds/music/main_theme.mp3',
        'sounds/effects/piece_drop.mp3',
        'sounds/effects/win_celebration.mp3',
        'sounds/effects/draw.mp3',
        'sounds/ui/button_click.mp3',
        'sounds/ui/button_hover.mp3',
        'sounds/ui/menu_open.mp3',
        'sounds/ui/menu_close.mp3',
        'sounds/ui/timer_tick.mp3',
        'sounds/ui/time_warning.mp3',
        'sounds/ui/time_up.mp3',
      ];

      for (final sound in sounds) {
        try {
          final source = AssetSource(sound);
          await _cacheSound(sound, source);
        } catch (e) {
          debugPrint('Error preloading sound $sound: $e');
        }
      }
    } finally {
      _isPreloading = false;
    }
  }

  Future<void> _cacheSound(String key, Source source) async {
    if (_soundCache.containsKey(key)) return;
    _soundCache[key] = source;
  }

  Future<void> _playSound(
      String soundPath, AudioPlayer player, bool isEnabled) async {
    if (!_isInitialized || !isEnabled) return;

    try {
      await player.stop();

      Source source;
      if (_soundCache.containsKey(soundPath)) {
        source = _soundCache[soundPath]!;
      } else {
        source = AssetSource(soundPath);
        await _cacheSound(soundPath, source);
      }

      await player.play(source);
    } catch (e) {
      debugPrint('Error playing sound $soundPath: $e');
      SoundService.showErrorSnackBar('Failed to play sound effect.');
    }
  }

  void _resetToDefaults() {
    _isMusicEnabled = true;
    _isEffectsEnabled = true;
    _isUIEnabled = true;
    _isAlarmEnabled = true;
    _musicVolume = 0.5;
    _effectsVolume = 0.7;
    _uiVolume = 0.5;
    _alarmVolume = 0.8;
    _isMusicPlaying = false;
    _currentMusic = null;
  }

  double _clampVolume(double volume) {
    return volume.clamp(_minVolume, _maxVolume);
  }

  // Music methods
  Future<void> playMainTheme() async {
    if (!_isInitialized || !_isMusicEnabled) return;
    try {
      if (_currentMusic == 'main_theme.mp3' && _isMusicPlaying) return;
      await _musicPlayer.stop();
      await _playSound(
          'sounds/music/main_theme.mp3', _musicPlayer, _isMusicEnabled);
      _currentMusic = 'main_theme.mp3';
    } catch (e) {
      debugPrint('Error playing main theme: $e');
      SoundService.showErrorSnackBar('Failed to play main theme.');
    }
  }

  // Effect methods
  Future<void> playPieceDrop() async {
    await _playSound(
        'sounds/effects/piece_drop.mp3', _effectsPlayer, _isEffectsEnabled);
  }

  Future<void> playWinCelebration() async {
    await _playSound('sounds/effects/win_celebration.mp3', _effectsPlayer,
        _isEffectsEnabled);
  }

  Future<void> playDraw() async {
    await _playSound(
        'sounds/effects/draw.mp3', _effectsPlayer, _isEffectsEnabled);
  }

  // UI methods
  Future<void> playButtonClick() async {
    await _playSound('sounds/ui/button_click.mp3', _uiPlayer, _isUIEnabled);
  }

  Future<void> playButtonHover() async {
    await _playSound('sounds/ui/button_hover.mp3', _uiPlayer, _isUIEnabled);
  }

  Future<void> playMenuOpen() async {
    await _playSound('sounds/ui/menu_open.mp3', _uiPlayer, _isUIEnabled);
  }

  Future<void> playMenuClose() async {
    await _playSound('sounds/ui/menu_close.mp3', _uiPlayer, _isUIEnabled);
  }

  // Alarm methods
  Future<void> playTimerTick() async {
    await _playSound('sounds/ui/timer_tick.mp3', _alarmPlayer, _isAlarmEnabled);
  }

  Future<void> playTimeWarning() async {
    await _playSound(
        'sounds/ui/time_warning.mp3', _alarmPlayer, _isAlarmEnabled);
  }

  Future<void> playTimeUp() async {
    await _playSound('sounds/ui/time_up.mp3', _alarmPlayer, _isAlarmEnabled);
  }

  // Control methods
  Future<void> stopMusic() async {
    if (!_isInitialized) return;
    try {
      await _musicPlayer.stop();
      _isMusicPlaying = false;
      _currentMusic = null;
    } catch (e) {
      debugPrint('Error stopping music: $e');
    }
  }

  Future<void> pauseMusic() async {
    if (!_isInitialized || !_isMusicPlaying) return;
    try {
      await _musicPlayer.pause();
      _isMusicPlaying = false;
    } catch (e) {
      debugPrint('Error pausing music: $e');
    }
  }

  Future<void> resumeMusic() async {
    if (!_isInitialized || _isMusicPlaying || _currentMusic == null) return;
    try {
      await _musicPlayer.resume();
      _isMusicPlaying = true;
    } catch (e) {
      debugPrint('Error resuming music: $e');
    }
  }

  // Settings methods
  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;
    if (!enabled) {
      await stopMusic();
    } else if (_currentMusic != null) {
      await playMainTheme();
    }
    await _saveSettings();
  }

  Future<void> setEffectsEnabled(bool enabled) async {
    _isEffectsEnabled = enabled;
    await _saveSettings();
  }

  Future<void> setUIEnabled(bool enabled) async {
    _isUIEnabled = enabled;
    await _saveSettings();
  }

  Future<void> setAlarmEnabled(bool enabled) async {
    _isAlarmEnabled = enabled;
    await _saveSettings();
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = _clampVolume(volume);
    await _musicPlayer.setVolume(_musicVolume);
    await _saveSettings();
  }

  Future<void> setEffectsVolume(double volume) async {
    _effectsVolume = _clampVolume(volume);
    await _effectsPlayer.setVolume(_effectsVolume);
    await _saveSettings();
  }

  Future<void> setUIVolume(double volume) async {
    _uiVolume = _clampVolume(volume);
    await _uiPlayer.setVolume(_uiVolume);
    await _saveSettings();
  }

  Future<void> setAlarmVolume(double volume) async {
    _alarmVolume = _clampVolume(volume);
    await _alarmPlayer.setVolume(_alarmVolume);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_musicEnabledKey, _isMusicEnabled);
      await prefs.setBool(_effectsEnabledKey, _isEffectsEnabled);
      await prefs.setBool(_uiEnabledKey, _isUIEnabled);
      await prefs.setBool(_alarmEnabledKey, _isAlarmEnabled);
      await prefs.setDouble(_musicVolumeKey, _musicVolume);
      await prefs.setDouble(_effectsVolumeKey, _effectsVolume);
      await prefs.setDouble(_uiVolumeKey, _uiVolume);
      await prefs.setDouble(_alarmVolumeKey, _alarmVolume);
    } catch (e) {
      debugPrint('Error saving sound settings: $e');
    }
  }

  // Getters
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isEffectsEnabled => _isEffectsEnabled;
  bool get isUIEnabled => _isUIEnabled;
  bool get isAlarmEnabled => _isAlarmEnabled;
  double get musicVolume => _musicVolume;
  double get effectsVolume => _effectsVolume;
  double get uiVolume => _uiVolume;
  double get alarmVolume => _alarmVolume;
  bool get isMusicPlaying => _isMusicPlaying;

  // Cleanup
  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
      await _effectsPlayer.dispose();
      await _uiPlayer.dispose();
      await _alarmPlayer.dispose();
      _soundCache.clear();
    } catch (e) {
      debugPrint('Error disposing sound service: $e');
    }
  }
}
