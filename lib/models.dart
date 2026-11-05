import 'config.dart';

/* ---------- finding the right player for a video id (same rules as the website) ---------- */

String _ytId(String x) {
  x = x.trim();
  final m = RegExp(
    r'(?:youtu\.be/|youtube(?:-nocookie)?\.com/(?:watch\?(?:[^\s]*&)?v=|embed/|shorts/|live/|v/))([\w-]{11})',
    caseSensitive: false,
  ).firstMatch(x);
  if (m != null) return m.group(1)!;
  return RegExp(r'^[\w-]{11}$').hasMatch(x) ? x : '';
}

String _ytEmbed(String id) => 'https://www.youtube-nocookie.com/embed/$id?rel=0&playsinline=1';

String _driveId(String x) {
  x = x.trim();
  final m = RegExp(
    r'(?:drive|docs)\.google\.com/(?:file/(?:u/\d+/)?d/|open\?(?:[^\s]*&)?id=|uc\?(?:[^\s]*&)?id=)([\w-]{20,})',
    caseSensitive: false,
  ).firstMatch(x);
  if (m != null) return m.group(1)!;
  return RegExp(r'^[\w-]{25,}$').hasMatch(x) ? x : '';
}

String _driveEmbed(String id) => 'https://drive.google.com/file/d/$id/preview';

String _baseEmbed(String code) {
  if (code.trim().isEmpty || Config.embedBase.isEmpty) return '';
  final id = code.trim().split('/').map(Uri.encodeComponent).join('/');
  return Config.embedBase.contains('{id}') ? Config.embedBase.replaceAll('{id}', id) : Config.embedBase + id;
}

String _rawEmbed(String embed, String id) {
  if (embed.isNotEmpty) return embed;
  id = id.trim();
  if (id.isEmpty) return '';
  if (RegExp(r'^(https?:)?//', caseSensitive: false).hasMatch(id)) {
    final y = _ytId(id);
    if (y.isNotEmpty) return _ytEmbed(y);
    final d = _driveId(id);
    return d.isNotEmpty ? _driveEmbed(d) : id;
  }
  final m = RegExp(r'^(yt|youtube|gd|drive|gdrive|lulu|main):\s*(.+)$', caseSensitive: false).firstMatch(id);
  if (m != null) {
    final kind = m.group(1)!.toLowerCase();
    final rest = m.group(2)!;
    if (kind == 'yt' || kind == 'youtube') {
      final y = _ytId(rest);
      return y.isNotEmpty ? _ytEmbed(y) : '';
    }
    if (kind == 'gd' || kind == 'drive' || kind == 'gdrive') {
      final d = _driveId(rest);
      return d.isNotEmpty ? _driveEmbed(d) : '';
    }
    return _baseEmbed(rest);
  }
  if (RegExp(r'^[\w-]{11}$').hasMatch(id)) return _ytEmbed(id);
  if (RegExp(r'^[\w-]{25,}$').hasMatch(id)) return _driveEmbed(id);
  return _baseEmbed(id);
}

// accepts a link or a pasted <iframe> and returns a safe https address, or ''
String _safeEmbed(String raw) {
  var s = raw.trim();
  final m = RegExp(r'''<iframe[^>]*\ssrc\s*=\s*["']([^"']+)["']''', caseSensitive: false).firstMatch(s);
  if (m != null) s = m.group(1)!;
  if (s.startsWith('//')) s = 'https:$s';
  final u = Uri.tryParse(s);
  if (u == null || u.scheme != 'https') return '';
  final host = u.host.replaceFirst(RegExp(r'^www\.'), '');
  if (host == 'youtu.be') {
    final id = _ytId(s);
    return id.isEmpty ? '' : _ytEmbed(id);
  }
  if ((host == 'youtube.com' || host == 'm.youtube.com') && u.path == '/watch') {
    final id = u.queryParameters['v'] ?? '';
    return RegExp(r'^[\w-]{11}$').hasMatch(id) ? _ytEmbed(id) : '';
  }
  if (host == 'vimeo.com' && RegExp(r'^/\d+').hasMatch(u.path)) return 'https://player.vimeo.com/video${u.path}';
  return s;
}

String _fullUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '${Config.siteUrl}/${path.replaceFirst(RegExp(r'^/+'), '')}';
}

/* ---------- a lecture / handout file ---------- */

class VFile {
  final String title;
  final String url;
  final String type;
  VFile(this.title, this.url, this.type);

  factory VFile.fromJson(Map<String, dynamic> j) =>
      VFile((j['title'] ?? 'Download').toString(), (j['file'] ?? '').toString(), (j['type'] ?? '').toString());

  Map<String, dynamic> toJson() => {'title': title, 'file': url, 'type': type};

  String get label {
    if (type.isNotEmpty) return type.toUpperCase();
    final path = Uri.tryParse(url)?.path ?? '';
    final m = RegExp(r'\.([A-Za-z0-9]{2,4})$').firstMatch(path);
    return m != null ? m.group(1)!.toUpperCase() : 'FILE';
  }
}

/* ---------- a video ---------- */

class Video {
  final String title;
  final String date;
  final String id;
  final String embed;
  final String file;
  final String thumb;
  final String thumbAuto;   // the picture found on the video host's own page (LuluStream etc.)
  final String duration;
  final List<String> tags;
  final List<VFile> files;

  Video({
    required this.title,
    required this.date,
    required this.id,
    required this.embed,
    required this.file,
    required this.thumb,
    required this.thumbAuto,
    required this.duration,
    required this.tags,
    required this.files,
  });

  factory Video.fromJson(Map<String, dynamic> j) {
    final tags = j['tags'] is List ? (j['tags'] as List).map((e) => e.toString()).toList() : <String>[];
    final files = <VFile>[];
    if (j['files'] is List) {
      for (final e in (j['files'] as List)) {
        if (e is Map) {
          final f = VFile.fromJson(Map<String, dynamic>.from(e));
          if (f.url.startsWith('https://')) files.add(f);
        }
      }
    }
    return Video(
      title: (j['title'] ?? '').toString(),
      date: (j['date'] ?? '').toString(),
      id: (j['id'] ?? '').toString(),
      embed: (j['embed'] ?? '').toString(),
      file: (j['file'] ?? '').toString(),
      thumb: (j['thumb'] ?? '').toString(),
      thumbAuto: (j['thumbAuto'] ?? '').toString(),
      duration: (j['duration'] ?? '').toString(),
      tags: tags,
      files: files,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date,
        'id': id,
        'embed': embed,
        'file': file,
        'thumb': thumb,
        'thumbAuto': thumbAuto,
        'duration': duration,
        'tags': tags,
        'files': files.map((f) => f.toJson()).toList(),
      };

  // the player address ('' for a direct video file or when it can't be played)
  String get embedUrl => file.isNotEmpty ? '' : _safeEmbed(_rawEmbed(embed, id));

  bool get playable => file.isNotEmpty || embedUrl.isNotEmpty;

  // the address that opens this video outside the app
  String get openUrl {
    if (file.isNotEmpty) return file;
    final e = embedUrl;
    final y = RegExp(r'youtube(?:-nocookie)?\.com/embed/([\w-]{11})', caseSensitive: false).firstMatch(e);
    if (y != null) return 'https://www.youtube.com/watch?v=${y.group(1)}';
    final d = RegExp(r'^https://drive\.google\.com/file/d/([\w-]+)/preview').firstMatch(e);
    if (d != null) return 'https://drive.google.com/file/d/${d.group(1)}/view';
    return e;
  }

  String get thumbUrl {
    if (thumb.isNotEmpty) return _fullUrl(thumb);
    final e = embedUrl;
    final y = RegExp(r'youtube(?:-nocookie)?\.com/embed/([\w-]{11})', caseSensitive: false).firstMatch(e);
    if (y != null) return 'https://i.ytimg.com/vi/${y.group(1)}/hqdefault.jpg';
    final d = RegExp(r'^https://drive\.google\.com/file/d/([\w-]+)/preview').firstMatch(e);
    if (d != null) return 'https://drive.google.com/thumbnail?id=${d.group(1)}&sz=w640';
    if (thumbAuto.isNotEmpty) return thumbAuto;
    return '';
  }

  // identifies the video in Saved / Recently watched
  String get key => file.isNotEmpty ? file : (embedUrl.isNotEmpty ? embedUrl : '$title|$date');
}

/* ---------- a community comment ---------- */

class Comment {
  final int id;
  final String name;
  final String message;
  final int rating;
  final int time;
  final List<Comment> replies;
  Comment(this.id, this.name, this.message, this.rating, this.time, this.replies);

  factory Comment.fromJson(Map<String, dynamic> j) {
    final reps = <Comment>[];
    if (j['replies'] is List) {
      for (final r in (j['replies'] as List)) {
        if (r is Map) reps.add(Comment.fromJson(Map<String, dynamic>.from(r)));
      }
    }
    int asInt(dynamic v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);
    return Comment(asInt(j['id']), (j['name'] ?? '').toString(), (j['message'] ?? '').toString(),
        asInt(j['rating']), asInt(j['time']), reps);
  }

  String get day {
    if (time <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(time);
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
