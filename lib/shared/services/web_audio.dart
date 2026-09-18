import 'dart:js_interop';

@JS('playFocusBellPattern')
external void _playFocusBellPattern(
  JSNumber frequency,
  JSNumber duration,
  JSNumber volume,
  JSString texture,
  JSNumber pulseCount,
);

@JS('focusAmbientPlay')
external void _focusAmbientPlay(JSString recipeJson, JSNumber volume);

@JS('focusAmbientStop')
external void _focusAmbientStop();

@JS('focusAmbientPause')
external void _focusAmbientPause();

@JS('focusAmbientResume')
external void _focusAmbientResume();

@JS('focusAmbientSetVolume')
external void _focusAmbientSetVolume(JSNumber volume);

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
  try {
    _playFocusBellPattern(
      frequency.toJS,
      duration.toJS,
      volume.toJS,
      texture.toJS,
      pulseCount.toJS,
    );
  } catch (_) {}
}

void playAmbientRecipeOnWeb(String recipeJson, double volume) {
  try {
    _focusAmbientPlay(recipeJson.toJS, volume.toJS);
  } catch (_) {}
}

void stopAmbientOnWeb() {
  try {
    _focusAmbientStop();
  } catch (_) {}
}

void pauseAmbientOnWeb() {
  try {
    _focusAmbientPause();
  } catch (_) {}
}

void resumeAmbientOnWeb() {
  try {
    _focusAmbientResume();
  } catch (_) {}
}

void setAmbientVolumeOnWeb(double volume) {
  try {
    _focusAmbientSetVolume(volume.toJS);
  } catch (_) {}
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
