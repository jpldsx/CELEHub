import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../config.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

// the video is shown by a tiny page on YOUR website (player.html), so the video host sees your real site address
String _playerUrl(Video v) {
  final base = '${Config.siteUrl}/player.html';
  if (v.file.isNotEmpty) return '$base?f=${Uri.encodeComponent(v.file)}';
  return '$base?u=${Uri.encodeComponent(v.embedUrl)}';
}

// look like normal Chrome on a phone (some video hosts refuse an Android "WebView")
const String _chromeUserAgent =
    'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

Future<void> openLink(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

class PlayerScreen extends StatefulWidget {
  final Video video;
  const PlayerScreen({super.key, required this.video});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _web;

  @override
  void initState() {
    super.initState();
    Store.addRecent(widget.video);
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setUserAgent(_chromeUserAgent)
      ..setNavigationDelegate(NavigationDelegate(
        // Ads try to jump to other pages. Say "no" quietly: no setState, no rebuild, no work,
        // so hundreds of blocked jumps can not slow the app down or crash it.
        onNavigationRequest: (req) {
          if (!req.isMainFrame) return NavigationDecision.navigate;               // the video box inside the page
          final u = req.url;
          if (u == 'about:blank' || u.startsWith('${Config.siteUrl}/player')) return NavigationDecision.navigate;
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(_playerUrl(widget.video)));
    _allowVideoHosts();
  }

  // Many video hosts need third-party cookies and a tap-to-play without extra blocking
  void _allowVideoHosts() {
    final platform = _web.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      final cookies = WebViewCookieManager().platform;
      if (cookies is AndroidWebViewCookieManager) {
        cookies.setAcceptThirdPartyCookies(platform, true);
      }
    }
  }

  @override
  void dispose() {
    // stop the video and any ad scripts the moment you leave this page
    try {
      _web.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: const BrandMark(size: 0.85),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: C.border)),
      ),
      body: AppBackdrop(
        child: Column(
          children: [
            Container(
              color: Colors.black,
              child: AspectRatio(aspectRatio: 16 / 9, child: WebViewWidget(controller: _web)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  SoftCard(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.text, height: 1.25)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(v.date, style: const TextStyle(fontSize: 13, color: C.muted)),
                            for (final t in v.tags) TagPill(t),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ValueListenableBuilder<int>(
                          valueListenable: Store.changes,
                          builder: (c, _, w) {
                            final fav = Store.isFav(v);
                            return SizedBox(
                              width: double.infinity,
                              child: fav
                                  ? OutlinedButton.icon(
                                      onPressed: () => Store.toggleFav(v),
                                      icon: const Icon(Icons.bookmark_rounded),
                                      label: const Text('Saved'),
                                    )
                                  : FilledButton.icon(
                                      onPressed: () => Store.toggleFav(v),
                                      icon: const Icon(Icons.bookmark_border_rounded),
                                      label: const Text('Save for later'),
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (v.files.isNotEmpty) ...[
                    const SectionTitle('Lecture notes and handouts'),
                    for (final f in v.files)
                      SoftCard(
                        margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(C.radius)),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: C.accentSoft, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.description_outlined, color: C.accent),
                          ),
                          title: Text(f.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                          subtitle: Text(f.label, style: const TextStyle(color: C.muted)),
                          trailing: const Icon(Icons.download_rounded, color: C.accent),
                          onTap: () => openLink(f.url),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
