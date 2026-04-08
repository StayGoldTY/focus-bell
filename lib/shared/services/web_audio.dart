import 'dart:js_interop';

@JS('playFocusBellTone')
external void _playFocusBellTone(
  JSNumber frequency,
  JSNumber duration,
  JSNumber volume,
);

@JS('requestFocusWakeLock')
external void _requestWakeLock();

@JS('releaseFocusWakeLock')
external void _releaseWakeLock();

void playToneOnWeb(double frequency, double duration, double volume) {
  _playFocusBellTone(frequency.toJS, duration.toJS, volume.toJS);
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
