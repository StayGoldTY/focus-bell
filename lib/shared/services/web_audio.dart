import 'dart:js_interop';

@JS('playFocusBellPattern')
external void _playFocusBellPattern(
  JSNumber frequency,
  JSNumber duration,
  JSNumber volume,
  JSString texture,
  JSNumber pulseCount,
);

@JS('requestFocusWakeLock')
external void _requestWakeLock();

@JS('releaseFocusWakeLock')
external void _releaseWakeLock();

void playBuiltInSoundOnWeb(
  double frequency,
  double duration,
  double volume,
  String texture,
  int pulseCount,
) {
  _playFocusBellPattern(
    frequency.toJS,
    duration.toJS,
    volume.toJS,
    texture.toJS,
    pulseCount.toJS,
  );
}

void playToneOnWeb(double frequency, double duration, double volume) {
  playBuiltInSoundOnWeb(frequency, duration, volume, 'digital', 1);
}

void requestWakeLockOnWeb() {
  try {
    _requestWakeLock();
  } catch (_) {}
}

void releaseWakeLockOnWeb() {
  try {
    _releaseWakeLock();
  } catch (_) {}
}
