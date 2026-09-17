// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

html.EventListener? _pageHideListener;
html.EventListener? _beforeUnloadListener;

void registerPageUnloadListener(void Function() onUnload) {
  unregisterPageUnloadListener();
  _pageHideListener = (_) => onUnload();
  _beforeUnloadListener = (_) => onUnload();
  html.window.addEventListener('pagehide', _pageHideListener);
  html.window.addEventListener('beforeunload', _beforeUnloadListener);
}

void unregisterPageUnloadListener() {
  if (_pageHideListener != null) {
    html.window.removeEventListener('pagehide', _pageHideListener);
    _pageHideListener = null;
  }
  if (_beforeUnloadListener != null) {
    html.window.removeEventListener('beforeunload', _beforeUnloadListener);
    _beforeUnloadListener = null;
  }
}
