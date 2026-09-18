// Stub implementations for non-web platforms (no-op).

void playBuiltInSoundOnWeb(
  double frequency,
  double duration,
  double volume,
  String texture,
  int pulseCount,
) {}

void playAmbientRecipeOnWeb(String recipeJson, double volume) {}

void stopAmbientOnWeb() {}

void pauseAmbientOnWeb() {}

void resumeAmbientOnWeb() {}

void setAmbientVolumeOnWeb(double volume) {}

void requestWakeLockOnWeb() {}

void releaseWakeLockOnWeb() {}
