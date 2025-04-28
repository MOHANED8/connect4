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
        SnackBar(content: Text(message)),
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

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing sound service: $e');
      _resetToDefaults();
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
      await _musicPlayer.play(AssetSource('sounds/music/main_theme.mp3'));
      _currentMusic = 'main_theme.mp3';
    } catch (e) {
      debugPrint('Error playing main theme: $e');
      SoundService.showErrorSnackBar('Failed to play main theme.');
    }
  }

  // Effect methods
  Future<void> playPieceDrop() async {
    if (!_isInitialized || !_isEffectsEnabled) return;
    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.play(AssetSource('sounds/effects/piece_drop.mp3'));
    } catch (e) {
      debugPrint('Error playing piece drop sound: $e');
      SoundService.showErrorSnackBar('Failed to play piece drop sound.');
    }
  }

  Future<void> playPieceLand() async {
    if (!_isInitialized || !_isEffectsEnabled) return;
    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.play(AssetSource('sounds/effects/piece_land.mp3'));
    } catch (e) {
      debugPrint('Error playing piece land sound: $e');
      SoundService.showErrorSnackBar('Failed to play piece land sound.');
    }
  }

  Future<void> playWinCelebration() async {
    if (!_isInitialized || !_isEffectsEnabled) return;
    try {
      await _effectsPlayer.stop();
      await _effectsPlayer
          .play(AssetSource('sounds/effects/win_celebration.mp3'));
    } catch (e) {
      debugPrint('Error playing win celebration sound: $e');
      SoundService.showErrorSnackBar('Failed to play win celebration sound.');
    }
  }

  Future<void> playDraw() async {
    if (!_isInitialized || !_isEffectsEnabled) return;
    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.play(AssetSource('sounds/effects/draw.mp3'));
    } catch (e) {
      debugPrint('Error playing draw sound: $e');
      SoundService.showErrorSnackBar('Failed to play draw sound.');
    }
  }

  // UI methods
  Future<void> playButtonClick() async {
    if (!_isInitialized || !_isUIEnabled) return;
    try {
      await _uiPlayer.stop();
      await _uiPlayer.play(AssetSource('sounds/ui/button_click.mp3'));
    } catch (e) {
      debugPrint('Error playing button click sound: $e');
      SoundService.showErrorSnackBar('Failed to play button click sound.');
    }
  }

  Future<void> playButtonHover() async {
    if (!_isInitialized || !_isUIEnabled) return;
    try {
      await _uiPlayer.stop();
      await _uiPlayer.play(AssetSource('sounds/ui/button_hover.mp3'));
    } catch (e) {
      debugPrint('Error playing button hover sound: $e');
      SoundService.showErrorSnackBar('Failed to play button hover sound.');
    }
  }

  Future<void> playMenuOpen() async {
    if (!_isInitialized || !_isUIEnabled) return;
    try {
      await _uiPlayer.stop();
      await _uiPlayer.play(AssetSource('sounds/ui/menu_open.mp3'));
    } catch (e) {
      debugPrint('Error playing menu open sound: $e');
      SoundService.showErrorSnackBar('Failed to play menu open sound.');
    }
  }

  Future<void> playMenuClose() async {
    if (!_isInitialized || !_isUIEnabled) return;
    try {
      await _uiPlayer.stop();
      await _uiPlayer.play(AssetSource('sounds/ui/menu_close.mp3'));
    } catch (e) {
      debugPrint('Error playing menu close sound: $e');
      SoundService.showErrorSnackBar('Failed to play menu close sound.');
    }
  }

  // Alarm methods
  Future<void> playTimerTick() async {
    if (!_isInitialized || !_isAlarmEnabled) return;
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.play(AssetSource('sounds/ui/timer_tick.mp3'));
    } catch (e) {
      debugPrint('Error playing timer tick sound: $e');
      SoundService.showErrorSnackBar('Failed to play timer tick sound.');
    }
  }

  Future<void> playTimeWarning() async {
    if (!_isInitialized || !_isAlarmEnabled) return;
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.play(AssetSource('sounds/ui/time_warning.mp3'));
    } catch (e) {
      debugPrint('Error playing time warning sound: $e');
      SoundService.showErrorSnackBar('Failed to play time warning sound.');
    }
  }

  Future<void> playTimeUp() async {
    if (!_isInitialized || !_isAlarmEnabled) return;
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.play(AssetSource('sounds/ui/time_up.mp3'));
    } catch (e) {
      debugPrint('Error playing time up sound: $e');
      SoundService.showErrorSnackBar('Failed to play time up sound.');
    }
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
      SoundService.showErrorSnackBar('Failed to stop music.');
    }
  }

  Future<void> pauseMusic() async {
    if (!_isInitialized) return;
    try {
      await _musicPlayer.pause();
      _isMusicPlaying = false;
    } catch (e) {
      debugPrint('Error pausing music: $e');
      SoundService.showErrorSnackBar('Failed to pause music.');
    }
  }

  Future<void> resumeMusic() async {
    if (!_isInitialized || !_isMusicEnabled || _currentMusic == null) return;
    try {
      await _musicPlayer.resume();
      _isMusicPlaying = true;
    } catch (e) {
      debugPrint('Error resuming music: $e');
      SoundService.showErrorSnackBar('Failed to resume music.');
    }
  }

  // Settings methods
  Future<void> setMusicEnabled(bool value) async {
    if (!_isInitialized) return;
    _isMusicEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, value);
    if (!value) {
      await stopMusic();
    }
  }

  Future<void> setEffectsEnabled(bool value) async {
    if (!_isInitialized) return;
    _isEffectsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_effectsEnabledKey, value);
  }

  Future<void> setUIEnabled(bool value) async {
    if (!_isInitialized) return;
    _isUIEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_uiEnabledKey, value);
  }

  Future<void> setAlarmEnabled(bool value) async {
    if (!_isInitialized) return;
    _isAlarmEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alarmEnabledKey, value);
  }

  Future<void> setMusicVolume(double value) async {
    if (!_isInitialized) return;
    _musicVolume = _clampVolume(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, _musicVolume);
    await _musicPlayer.setVolume(_musicVolume);
  }

  Future<void> setEffectsVolume(double value) async {
    if (!_isInitialized) return;
    _effectsVolume = _clampVolume(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_effectsVolumeKey, _effectsVolume);
    await _effectsPlayer.setVolume(_effectsVolume);
  }

  Future<void> setUIVolume(double value) async {
    if (!_isInitialized) return;
    _uiVolume = _clampVolume(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_uiVolumeKey, _uiVolume);
    await _uiPlayer.setVolume(_uiVolume);
  }

  Future<void> setAlarmVolume(double value) async {
    if (!_isInitialized) return;
    _alarmVolume = _clampVolume(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_alarmVolumeKey, _alarmVolume);
    await _alarmPlayer.setVolume(_alarmVolume);
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isEffectsEnabled => _isEffectsEnabled;
  bool get isUIEnabled => _isUIEnabled;
  bool get isAlarmEnabled => _isAlarmEnabled;
  double get musicVolume => _musicVolume;
  double get effectsVolume => _effectsVolume;
  double get uiVolume => _uiVolume;
  double get alarmVolume => _alarmVolume;
  bool get isMusicPlaying => _isMusicPlaying;
  String? get currentMusic => _currentMusic;

  Future<void> dispose() async {
    if (!_isInitialized) return;
    try {
      await _musicPlayer.stop();
      await _effectsPlayer.stop();
      await _uiPlayer.stop();
      await _alarmPlayer.stop();
      await _musicPlayer.dispose();
      await _effectsPlayer.dispose();
      await _uiPlayer.dispose();
      await _alarmPlayer.dispose();
      _isInitialized = false;
      _isMusicPlaying = false;
      _currentMusic = null;
    } catch (e) {
      debugPrint('Error disposing sound service: $e');
      SoundService.showErrorSnackBar('Failed to dispose sound service.');
    }
  }
}
