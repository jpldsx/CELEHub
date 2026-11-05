import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../store.dart';
import 'player_screen.dart';

// one video in a list (used by Study, Break and Saved)
class VideoCard extends StatelessWidget {
  final Video video;
  const VideoCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final v = video;
    final pic = v.thumbUrl;
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: scheme.surfaceContainerHighest,
      child: Center(child: Icon(Icons.school, size: 40, color: scheme.primary)),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(video: v))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  pic.isEmpty
                      ? placeholder
                      : Image.network(pic, fit: BoxFit.cover, errorBuilder: (c, e, s) => placeholder),
                  if (v.files.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withAlpha(170), borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.download, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('${v.files.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ]),
                      ),
                    ),
                  const Center(child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(v.date, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoListScreen extends StatefulWidget {
  final String page; // 'study' or 'break'
  const VideoListScreen({super.key, required this.page});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> with AutomaticKeepAliveClientMixin {
  List<Video> _all = <Video>[];
  bool _loading = true;
  bool _fromCache = false;
  String _query = '';
  String _tag = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _all = Store.cachedVideos(widget.page);          // show the last list straight away
    _loading = _all.isEmpty;
    _load();
  }

  Future<void> _load() async {
    final r = await Api.videos(widget.page);
    if (!mounted) return;
    setState(() {
      _all = r.videos;
      _fromCache = r.fromCache;
      _loading = false;
    });
  }

  List<String> get _tags {
    final seen = <String>[];
    for (final v in _all) {
      for (final t in v.tags) {
        if (t.isNotEmpty && !seen.contains(t)) seen.add(t);
      }
    }
    return seen;
  }

  List<Video> get _shown {
    final q = _query.trim().toLowerCase();
    return _all.where((v) {
      if (_tag.isNotEmpty && !v.tags.contains(_tag)) return false;
      if (q.isNotEmpty && !v.title.toLowerCase().contains(q)) return false;
      return v.playable;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tags = _tags;
    final shown = _shown;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: widget.page == 'study' ? 'Search solved problems' : 'Search break time videos',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              isDense: true,
            ),
            onChanged: (s) => setState(() => _query = s),
          ),
        ),
        if (tags.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                  child: ChoiceChip(label: const Text('All'), selected: _tag.isEmpty, onSelected: (_) => setState(() => _tag = '')),
                ),
                for (final t in tags)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                    child: ChoiceChip(label: Text(t), selected: _tag == t, onSelected: (_) => setState(() => _tag = _tag == t ? '' : t)),
                  ),
              ],
            ),
          ),
        if (_fromCache)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Text('Offline - showing the last list saved on your phone.', style: TextStyle(fontSize: 12)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: shown.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 80),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _all.isNotEmpty
                                  ? 'No videos match.'
                                  : (_fromCache && Api.lastError.isNotEmpty)
                                      ? Api.lastError
                                      : 'The website has no videos in its database for this page yet (the ones in js/videos.js are not included until you run the import). Pull down to refresh.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ])
                      : ListView.builder(
                          itemCount: shown.length,
                          itemBuilder: (c, i) => VideoCard(video: shown[i]),
                        ),
                ),
        ),
      ],
    );
  }
}
