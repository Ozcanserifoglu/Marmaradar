import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:radar_alert/core/audio/voice_phrases.dart';

/// On-device MP3 cache for TTS clips keyed by phrase + params.
class VoiceClipCache {
  Directory? _dir;

  Future<Directory> _ensureDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'tts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  Future<File> _fileFor(String phraseKey, Map<String, dynamic> params) async {
    final dir = await _ensureDir();
    final key = VoicePhrases.localCacheKey(phraseKey, params);
    final safe = key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return File(p.join(dir.path, '$safe.mp3'));
  }

  Future<File?> lookup(String phraseKey, Map<String, dynamic> params) async {
    final file = await _fileFor(phraseKey, params);
    if (await file.exists() && await file.length() > 0) return file;
    return null;
  }

  Future<File> put(
    String phraseKey,
    Map<String, dynamic> params,
    Uint8List bytes,
  ) async {
    final file = await _fileFor(phraseKey, params);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
