import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

// everything the app remembers on the phone
class Store {
  static late SharedPreferences _p;
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);   // bumped when Saved / Recent change

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  // ---- visitor session (the cookie the website gives after the quick survey) ----
  static String get cookie => _p.getString('cookie') ?? '';
  static Future<void> setCookie(String v) => _p.setString('cookie', v);
  static String get name => _p.getString('name') ?? '';
  static Future<void> setName(String v) => _p.setString('name', v);
  static Future<void> clearSession() async {
    await _p.remove('cookie');
    await _p.remove('name');
  }

  // ---- under-18 flag (24 hours, like the website) ----
  static bool get minorFlagged {
    final t = _p.getInt('minor') ?? 0;
    return t > 0 && DateTime.now().millisecondsSinceEpoch - t < 86400000;
  }

  static Future<void> flagMinor() => _p.setInt('minor', DateTime.now().millisecondsSinceEpoch);
  static Future<void> clearMinor() => _p.remove('minor');

  // ---- the last video list, so the app still opens offline ----
  static Future<void> saveVideos(String page, String json) => _p.setString('videos_$page', json);
  static List<Video> cachedVideos(String page) {
    final s = _p.getString('videos_$page');
    if (s == null) return <Video>[];
    try {
      final d = jsonDecode(s);
      if (d is List) {
        return d.whereType<Map>().map((e) => Video.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}
    return <Video>[];
  }

  // ---- Saved and Recently watched ----
  static List<Video> _read(String k) {
    final out = <Video>[];
    for (final s in _p.getStringList(k) ?? <String>[]) {
      try {
        out.add(Video.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map)));
      } catch (_) {}
    }
    return out;
  }

  static Future<void> _write(String k, List<Video> list) async {
    await _p.setStringList(k, list.map((v) => jsonEncode(v.toJson())).toList());
    changes.value++;
  }

  static List<Video> favorites() => _read('favs');
  static List<Video> recents() => _read('recents');
  static bool isFav(Video v) => favorites().any((x) => x.key == v.key);

  static Future<void> toggleFav(Video v) async {
    final list = favorites();
    final i = list.indexWhere((x) => x.key == v.key);
    if (i >= 0) {
      list.removeAt(i);
    } else {
      list.insert(0, v);
    }
    await _write('favs', list);
  }

  static Future<void> addRecent(Video v) async {
    final list = recents();
    list.removeWhere((x) => x.key == v.key);
    list.insert(0, v);
    if (list.length > 30) list.removeRange(30, list.length);
    await _write('recents', list);
  }

  static Future<void> clearRecents() async {
    await _p.remove('recents');
    changes.value++;
  }
}
