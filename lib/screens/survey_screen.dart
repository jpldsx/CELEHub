import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../api.dart';
import '../config.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'player_screen.dart' show openLink;

// the Cloudflare check (a tiny web page that hands the result back to the app)
const String _turnstileHtml = r'''<!doctype html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=ready" async defer></script>
<style>html,body{margin:0;height:100%;background:transparent;display:flex;align-items:center;justify-content:center}</style>
</head><body><div id="w"></div>
<script>
function ready(){
  turnstile.render('#w',{
    sitekey:'__KEY__',
    callback:function(t){Token.postMessage(t)},
    'expired-callback':function(){Token.postMessage('')},
    'error-callback':function(){Token.postMessage('')}
  });
}
</script></body></html>''';

class SurveyScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SurveyScreen({super.key, required this.onDone});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _school = TextEditingController();
  final TextEditingController _center = TextEditingController();
  late final WebViewController _check;
  String _token = '';
  bool _consent = false;
  bool _busy = false;
  bool _minor = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _minor = Store.minorFlagged;
    _check = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel('Token', onMessageReceived: (m) {
        if (mounted) setState(() => _token = m.message);
      });
    _loadCheck();
  }

  void _loadCheck() {
    _check.loadHtmlString(_turnstileHtml.replaceAll('__KEY__', Config.turnstileSiteKey), baseUrl: Config.siteUrl);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _school.dispose();
    _center.dispose();
    super.dispose();
  }

  bool get _ready =>
      _token.isNotEmpty &&
      _consent &&
      !_busy &&
      _name.text.trim().length >= 2 &&
      _age.text.trim().isNotEmpty &&
      _school.text.trim().isNotEmpty &&
      _center.text.trim().isNotEmpty;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final r = await Api.submitSurvey(
      fullName: _name.text.trim(),
      age: _age.text.trim(),
      school: _school.text.trim(),
      reviewCenter: _center.text.trim(),
      token: _token,
    );
    if (!mounted) return;
    if (r.ok) {
      widget.onDone();
      return;
    }
    if (r.minor) {
      await Store.flagMinor();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _minor = true;
      });
      return;
    }
    // the security check can only be used once, so ask for a fresh one
    setState(() {
      _busy = false;
      _error = r.message;
      _token = '';
    });
    _loadCheck();
  }

  Widget _field(TextEditingController c, String label, {TextInputType? type, int? max, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLength: max,
        textCapitalization: type == null ? TextCapitalization.words : TextCapitalization.none,
        decoration: InputDecoration(labelText: label, hintText: hint, counterText: ''),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_minor) return _minorView(context);
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 6),
            const BrandMark(size: 1.15),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(gradient: C.hero, borderRadius: BorderRadius.circular(C.radius), boxShadow: C.shadowMd),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome to CELEHub', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('A quick survey first. It takes less than a minute and gives you your own visitor ID.', style: TextStyle(color: Color(0xD9FFFFFF), height: 1.35)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _field(_name, 'Full name', max: 80, hint: 'First and last name'),
            _field(_age, 'Age', type: TextInputType.number, max: 2),
            _field(_school, 'College or university', max: 100),
            _field(_center, 'Review center (or "None")', max: 100),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              title: const Text('I agree to the Privacy Policy and Terms.', style: TextStyle(fontSize: 14)),
            ),
            Wrap(spacing: 14, children: [
              TextButton(onPressed: () => openLink('${Config.siteUrl}/privacy.html'), child: const Text('Privacy Policy')),
              TextButton(onPressed: () => openLink('${Config.siteUrl}/terms.html'), child: const Text('Terms')),
            ]),
            SizedBox(height: 78, child: WebViewWidget(controller: _check)),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _ready ? _submit : null,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue to CELEHub'),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _minorView(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48),
                const SizedBox(height: 12),
                Text('CELEHub is for ages 18 and up', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Text(
                  'Nothing was saved. Here is a place with free lessons made for your age.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton(onPressed: () => openLink(Config.minorUrl), child: const Text('Open free lessons')),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
