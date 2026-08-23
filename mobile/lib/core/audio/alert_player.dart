import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart' hide AVAudioSessionCategory;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:radar_alert/core/audio/voice_clip_cache.dart';
import 'package:radar_alert/core/audio/voice_phrases.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';

class AlertPlayer {
  AlertPlayer({
    RadarApiClient? api,
    VoiceClipCache? cache,
    AudioPlayer? audioPlayer,
  })  : _api = api ?? RadarApiClient(),
        _cache = cache ?? VoiceClipCache(),
        _audio = audioPlayer ?? AudioPlayer(),
        _tts = FlutterTts(),
        _notifications = FlutterLocalNotificationsPlugin();

  final RadarApiClient _api;
  final VoiceClipCache _cache;
  final AudioPlayer _audio;
  final FlutterTts _tts;
  final FlutterLocalNotificationsPlugin _notifications;

  bool _initialized = false;
  bool _sessionReady = false;
  bool _speaking = false;
  String? _currentKey;
  bool _prefetchStarted = false;
  Completer<void>? _ttsDone;

  void _onTtsFinished() {
    final done = _ttsDone;
    if (done != null && !done.isCompleted) {
      done.complete();
    }
  }

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _configureAudioSession();
    await _audio.setReleaseMode(ReleaseMode.stop);
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1);
      _tts.setCompletionHandler(_onTtsFinished);
      _tts.setCancelHandler(_onTtsFinished);
      _tts.setErrorHandler((_) => _onTtsFinished());
    } catch (_) {}
    _initialized = true;
  }

  Future<void> _configureAudioSession() async {
    if (_sessionReady) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            flags: AndroidAudioFlags.audibilityEnforced,
            usage: AndroidAudioUsage.assistanceNavigationGuidance,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
          androidWillPauseWhenDucked: false,
        ),
      );
      _sessionReady = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('audio session configure failed: $e');
      }
    }
  }

  Future<void> showCameraAlert({
    required String title,
    required String body,
    bool playSound = true,
  }) async {
    await init();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'radar_camera_alerts',
        'Hız Kamerası Uyarıları',
        channelDescription: 'Yaklaşan sabit hız kamerası uyarıları',
        importance: Importance.max,
        priority: Priority.high,
        playSound: playSound,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: playSound,
      ),
    );
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
    if (kDebugMode) {
      debugPrint('ALERT: $title — $body');
    }
  }

  Future<void> showCorridorWarning({
    required String title,
    required String body,
    bool playSound = true,
  }) async {
    await showCameraAlert(title: title, body: body, playSound: playSound);
  }

  /// Plays a catalog voice clip (with on-device cache) and shows a notification.
  /// On TTS failure, falls back to the notification system sound.
  Future<void> speakAlert({
    required String phraseKey,
    Map<String, dynamic> params = const {},
    required String title,
    required String body,
  }) async {
    await init();
    final cacheKey = VoicePhrases.localCacheKey(phraseKey, params);
    if (_speaking && _currentKey == cacheKey) return;

    var voicePlayed = false;
    try {
      voicePlayed = await _playPhrase(phraseKey, params);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('voice alert failed: $e');
      }
    }

    await showCameraAlert(
      title: title,
      body: body,
      playSound: !voicePlayed,
    );
  }

  Future<bool> _playPhrase(
    String phraseKey,
    Map<String, dynamic> params,
  ) async {
    final cacheKey = VoicePhrases.localCacheKey(phraseKey, params);
    _speaking = true;
    _currentKey = cacheKey;
    try {
      var file = await _cache.lookup(phraseKey, params);
      if (file == null) {
        final bytes = await _api.speakTts(
          phraseKey: phraseKey,
          params: params,
        );
        file = await _cache.put(phraseKey, params, bytes);
      }

      await _configureAudioSession();
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
      } catch (_) {}

      await _audio.stop();
      await _audio.setVolume(1);
      await _audio.play(DeviceFileSource(file.path));
      if (_audio.state != PlayerState.playing) {
        throw StateError('voice clip did not start');
      }
      unawaited(_clearSpeakingWhenDone(
        cacheKey,
        _audio.onPlayerComplete.first,
      ));
      return true;
    } catch (_) {
      try {
        final spoken = VoicePhrases.spokenText(phraseKey, params);
        await _tts.stop();
        final ttsDone = Completer<void>();
        _ttsDone = ttsDone;
        try {
          _tts.setCompletionHandler(_onTtsFinished);
          _tts.setCancelHandler(_onTtsFinished);
          _tts.setErrorHandler((_) => _onTtsFinished());
        } catch (_) {}
        final spokenOk = await _tts.speak(spoken);
        if (spokenOk != 1) {
          throw StateError('on-device tts did not start');
        }
        unawaited(_clearSpeakingWhenDone(cacheKey, ttsDone.future));
        return true;
      } catch (e) {
        if (_currentKey == cacheKey) {
          _speaking = false;
          _currentKey = null;
        }
        rethrow;
      }
    }
  }

  Future<void> _clearSpeakingWhenDone(String cacheKey, Future<void> wait) async {
    try {
      await wait.timeout(const Duration(seconds: 12));
    } catch (_) {}
    if (_currentKey == cacheKey) {
      _speaking = false;
      _currentKey = null;
    }
  }

  /// Best-effort prefetch of the TTS catalog into on-device cache.
  Future<void> prefetchCatalog() async {
    if (_prefetchStarted) return;
    _prefetchStarted = true;
    try {
      final hasSession = await _api.tokenStore.hasSession;
      if (!hasSession) {
        _prefetchStarted = false;
        return;
      }
      final entries = await _api.fetchTtsCatalog();
      for (final entry in entries) {
        final phraseKey = entry.phraseKey;
        final params = <String, dynamic>{};
        if (entry.distanceM != null) {
          params['distance_m'] = entry.distanceM;
        }
        final existing = await _cache.lookup(phraseKey, params);
        if (existing != null) continue;
        try {
          final bytes = await _api.speakTts(
            phraseKey: phraseKey,
            params: params,
          );
          await _cache.put(phraseKey, params, bytes);
        } catch (_) {
          // Continue prefetching other clips.
        }
      }
    } catch (e) {
      _prefetchStarted = false;
      if (kDebugMode) {
        debugPrint('tts prefetch failed: $e');
      }
    }
  }

  Future<void> dispose() async {
    await _audio.dispose();
  }
}
