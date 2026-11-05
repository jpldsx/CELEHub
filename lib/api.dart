import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'models.dart';
import 'store.dart';

class VideosResult {
  final List<Video> videos;
  final bool fromCache;
  VideosResult(this.videos, this.fromCache);
}

class SurveyResult {
  final bool ok;
  final bool minor;
  final String message;
  SurveyResult(this.ok, this.minor, this.message);
}

// talks to your CELEHub website (the same addresses the website uses)
class Api {
  static const String _ua = 'CELEHubApp/1.0 (Android)';

  static Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{'User-Agent': _ua, 'Accept': 'application/json'};
    final c = Store.cookie;
    if (c.isNotEmpty) h['Cookie'] = 'ct_session=$c';
    if (json) h['Content-Type'] = 'application/json';
    return h;
  }

  static Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${Config.siteUrl}$path').replace(queryParameters: query);

  static Future<void> _saveCookie(http.Response r) async {
    final sc = r.headers['set-cookie'];
    if (sc == null) return;
    final m = RegExp(r'ct_session=([^;,\s]*)').firstMatch(sc);
    if (m != null) await Store.setCookie(m.group(1)!);
  }

  static dynamic _decode(http.Response r) {
    try {
      return jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  /* ---------- videos ---------- */

  // why the last load failed (shown on screen when the list is empty)
  static String lastError = '';

  static Future<VideosResult> videos(String page) async {
    lastError = '';
    try {
      final r = await http.get(_uri('/api/videos', {'page': page}), headers: _headers()).timeout(const Duration(seconds: 15));
      final d = _decode(r);
      if (r.statusCode == 200 && d is Map && d['ok'] == true && d['videos'] is List) {
        await Store.saveVideos(page, jsonEncode(d['videos']));
        final list = (d['videos'] as List)
            .whereType<Map>()
            .map((e) => Video.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return VideosResult(list, false);
      }
      if (d == null) {
        lastError = 'The website sent a web page instead of the video list (HTTP ${r.statusCode}). Cloudflare may be blocking the app, or siteUrl in config.dart is not your site.';
      } else {
        lastError = 'The website answered, but not with a video list (HTTP ${r.statusCode}). Is the database (D1) connected?';
      }
    } catch (e) {
      lastError = 'Could not reach ${Config.siteUrl}. Check your internet and siteUrl in config.dart.';
    }
    return VideosResult(Store.cachedVideos(page), true);
  }

  /* ---------- the quick survey ---------- */

  // returns the visitor's name when the saved session is still valid, otherwise ''
  static Future<String> checkSession() async {
    if (Store.cookie.isEmpty) return '';
    try {
      final r = await http.get(_uri('/api/survey'), headers: _headers()).timeout(const Duration(seconds: 12));
      final d = _decode(r);
      if (r.statusCode == 200 && d is Map) {
        final n = d['name'];
        if (n is String && n.isNotEmpty) {
          await Store.setName(n);
          return n;
        }
        await Store.clearSession();
        return '';
      }
    } catch (_) {
      return Store.name;                        // offline: keep the visitor in
    }
    return Store.name;
  }

  static Future<SurveyResult> submitSurvey({
    required String fullName,
    required String age,
    required String school,
    required String reviewCenter,
    required String token,
  }) async {
    try {
      final body = jsonEncode({
        'fullName': fullName,
        'age': age,
        'school': school,
        'reviewCenter': reviewCenter,
        'consent': true,
        'turnstileToken': token,
      });
      final r = await http
          .post(_uri('/api/survey'), headers: _headers(json: true), body: body)
          .timeout(const Duration(seconds: 25));
      final d = _decode(r);
      if (d is Map && d['ok'] == true) {
        await _saveCookie(r);
        await Store.setName((d['name'] ?? 'Visitor').toString());
        return SurveyResult(true, false, '');
      }
      if (d is Map && d['minor'] == true) return SurveyResult(false, true, (d['message'] ?? '').toString());
      final msg = d is Map ? (d['message'] ?? '').toString() : '';
      return SurveyResult(false, false, msg.isNotEmpty ? msg : 'Something went wrong. Please try again.');
    } catch (_) {
      return SurveyResult(false, false, 'No connection. Check your internet and try again.');
    }
  }

  static Future<void> signOut() async {
    try {
      await http.delete(_uri('/api/survey'), headers: _headers()).timeout(const Duration(seconds: 10));
    } catch (_) {}
    await Store.clearSession();
  }

  /* ---------- community ---------- */

  static Future<List<Comment>?> comments() async {
    try {
      final r = await http.get(_uri('/api/feedback'), headers: _headers()).timeout(const Duration(seconds: 15));
      final d = _decode(r);
      if (d is Map && d['ok'] == true && d['comments'] is List) {
        return (d['comments'] as List)
            .whereType<Map>()
            .map((e) => Comment.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  // returns null when it worked, 'AUTH' when the survey must be done again, or an error message
  static Future<String?> postComment(String message, {int rating = 5, int? parentId}) async {
    try {
      final body = jsonEncode({
        'message': message,
        if (parentId != null) 'parentId': parentId else 'rating': rating,
      });
      final r = await http
          .post(_uri('/api/feedback'), headers: _headers(json: true), body: body)
          .timeout(const Duration(seconds: 15));
      final d = _decode(r);
      if (d is Map && d['ok'] == true) return null;
      if (r.statusCode == 401) return 'AUTH';
      if (r.statusCode == 429) return 'Too many posts. Please wait a minute.';
      return 'Could not post. Please try again.';
    } catch (_) {
      return 'No connection. Check your internet and try again.';
    }
  }
}
