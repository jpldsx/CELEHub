import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'player_screen.dart';

// one video in a list (used by Study, Break and Saved) - styled like the website cards
class VideoCard extends StatelessWidget {
  final Video video;
  const VideoCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final v = video;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 7, 16, 7),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(C.radius),
        border: Border.all(color: C.border),
        boxShadow: C.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
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
                    VideoThumb(url: v.thumbUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x59000000)],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: Color(0xE6FFFFFF),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 14)],
                        ),
                        child: const Icon(Icons.play_arrow_rounded, size: 34, color: C.accent),
                      ),
                    ),
                    if (v.duration.isNotEmpty)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(6)),
                          child: Text(v.duration, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (v.files.isNotEmpty)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xCC1B2033), borderRadius: BorderRadius.circular(999)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.attach_file_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 3),
                            Text('${v.files.length} file${v.files.length == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: C.text, height: 1.25)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(v.date, style: const TextStyle(fontSize: 12.5, color: C.muted)),
                        for (final t in v.tags.take(3)) TagPill(t),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final study = widget.page == 'study';
    return Column(
      children: [
        HeroBanner(
          title: study ? 'Solved Problems' : 'Break Time',
          subtitle: study ? 'Step by step CE solutions' : 'Rest your brain, then get back to it',
          pill: '${_shown.length} video${_shown.length == 1 ? '' : 's'}',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: study ? 'Search solved problems' : 'Search break time videos',
              prefixIcon: const Icon(Icons.search_rounded, color: C.muted),
            ),
            onChanged: (s) => setState(() => _query = s),
          ),
        ),
        if (tags.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterPill(label: 'All', selected: _tag.isEmpty, onTap: () => setState(() => _tag = '')),
                for (final t in tags) FilterPill(label: t, selected: _tag == t, onTap: () => setState(() => _tag = _tag == t ? '' : t)),
              ],
            ),
          ),
        if (_fromCache)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(color: C.accentSoft, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: const Text('Offline - showing the last list saved on your phone.', style: TextStyle(fontSize: 12, color: C.accent, fontWeight: FontWeight.w600)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: shown.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 40),
                          EmptyState(
                            icon: Icons.video_library_outlined,
                            text: _all.isNotEmpty
                                ? 'No videos match.'
                                : (_fromCache && Api.lastError.isNotEmpty)
                                    ? Api.lastError
                                    : 'The website has no videos in its database for this page yet (the ones in js/videos.js are not included until you run the import). Pull down to refresh.',
                          ),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: shown.length,
                          itemBuilder: (c, i) => VideoCard(video: shown[i]),
                        ),
                ),
        ),
      ],
    );
  }
}
