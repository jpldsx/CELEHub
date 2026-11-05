import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config.dart';
import '../models.dart';
import '../store.dart';

String _attr(String s) => s.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;');

String _playerHtml(Video v) {
  const style = 'html,body{margin:0;height:100%;background:#000}iframe,video{border:0;width:100%;height:100%}';
  if (v.file.isNotEmpty) {
    return '<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">'
        '<style>$style</style></head><body><video controls playsinline src="${_attr(v.file)}"></video></body></html>';
  }
  return '<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">'
      '<style>$style</style></head><body><iframe src="${_attr(v.embedUrl)}" '
      'allow="autoplay; fullscreen; encrypted-media; picture-in-picture" allowfullscreen></iframe></body></html>';
}

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
      ..setNavigationDelegate(NavigationDelegate(onNavigationRequest: (req) {
        final u = req.url;
        if (u == 'about:blank' || u.startsWith(Config.siteUrl)) return NavigationDecision.navigate;
        return req.isMainFrame ? NavigationDecision.prevent : NavigationDecision.navigate;   // the page can't wander off
      }))
      ..loadHtmlString(_playerHtml(widget.video), baseUrl: Config.siteUrl);
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
