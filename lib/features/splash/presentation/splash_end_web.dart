import 'dart:js_interop';

import 'package:web/web.dart' as web;

void bindHtmlSplashEnd(void Function() onDone) {
  final node = web.document.getElementById('ghofran-splash');
  if (node == null || !node.isA<web.HTMLVideoElement>()) {
    onDone();
    return;
  }
  final video = node as web.HTMLVideoElement;
  var done = false;
  void finish() {
    if (done) return;
    done = true;
    video.remove();
    onDone();
  }

  if (video.ended) {
    finish();
    return;
  }

  void onEnded(web.Event _) => finish();
  void onError(web.Event _) => finish();
  video.addEventListener('ended', onEnded.toJS);
  video.addEventListener('error', onError.toJS);
  video.muted = true;
  video.play();
  video.addEventListener('click', ((web.Event _) => finish()).toJS);
  Future<void>.delayed(const Duration(seconds: 8), finish);
  void pollRemoved() {
    if (done) return;
    if (web.document.getElementById('ghofran-splash') == null) {
      finish();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 200), pollRemoved);
  }

  pollRemoved();
}

void removeHtmlSplash() {
  web.document.getElementById('ghofran-splash')?.remove();
}
