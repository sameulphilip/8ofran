import 'package:web/web.dart' as web;

void bindHtmlSplashEnd(void Function() onDone) {
  // Web boot is covered by the HTML branding layer.
  onDone();
}

void removeHtmlSplash() {
  web.document.documentElement?.setAttribute('data-flutter-ready', '1');
  _tryRemoveSplash();
}

void _tryRemoveSplash() {
  final doc = web.document;
  final ready = doc.documentElement?.getAttribute('data-flutter-ready') == '1';
  if (!ready) return;

  final video = doc.getElementById('ghofran-splash');
  final splashDone =
      video == null || video.getAttribute('data-splash-done') == '1';

  if (!splashDone) {
    Future<void>.delayed(const Duration(milliseconds: 120), _tryRemoveSplash);
    return;
  }

  doc.getElementById('ghofran-splash-root')?.remove();
  video?.remove();
}
