import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../config.dart';
import '../models.dart';
import '../store.dart';

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
      ..setNavigationDelegate(NavigationDelegate(onNavigationRequest: (req) {
        final u = req.url;
        if (u == 'about:blank' || u.startsWith(Config.siteUrl)) return NavigationDecision.navigate;
        return req.isMainFrame ? NavigationDecision.prevent : NavigationDecision.navigate;   // the page can't wander off
      }))
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
  Widget build(BuildContext context) {
    final v = widget.video;
    return Scaffold(
      appBar: AppBar(title: Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Column(
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: WebViewWidget(controller: _web)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(v.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(v.date, style: Theme.of(context).textTheme.bodySmall),
                if (v.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final t in v.tags) Chip(label: Text(t), visualDensity: VisualDensity.compact)]),
                ],
                const SizedBox(height: 14),
                const Text('If the player stays blank, tap "Open outside".', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                SelectableText('Source: ${v.file.isNotEmpty ? v.file : v.embedUrl}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: Store.changes,
                      builder: (c, _, w) {
                        final fav = Store.isFav(v);
                        return FilledButton.tonalIcon(
                          onPressed: () => Store.toggleFav(v),
                          icon: Icon(fav ? Icons.bookmark : Icons.bookmark_border),
                          label: Text(fav ? 'Saved' : 'Save'),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => openLink(v.openUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open outside'),
                    ),
                  ],
                ),
                if (v.files.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text('Lecture notes and handouts', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  for (final f in v.files)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(f.title),
                        subtitle: Text(f.label),
                        trailing: const Icon(Icons.download),
                        onTap: () => openLink(f.url),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
