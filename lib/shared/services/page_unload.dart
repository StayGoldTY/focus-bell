import 'page_unload_stub.dart'
    if (dart.library.html) 'page_unload_web.dart' as impl;

void registerPageUnloadListener(void Function() onUnload) {
  impl.registerPageUnloadListener(onUnload);
}

void unregisterPageUnloadListener() {
  impl.unregisterPageUnloadListener();
}
