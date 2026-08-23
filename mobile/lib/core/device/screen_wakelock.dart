import 'package:wakelock_plus/wakelock_plus.dart';

/// Nested holds so tracking + replay can both keep the screen on.
class ScreenWakelock {
  ScreenWakelock._();

  static int _holds = 0;

  static Future<void> acquire() async {
    _holds++;
    if (_holds == 1) {
      await WakelockPlus.enable();
    }
  }

  static Future<void> release() async {
    if (_holds <= 0) return;
    _holds--;
    if (_holds == 0) {
      await WakelockPlus.disable();
    }
  }
}
