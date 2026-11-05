import 'package:flutter/material.dart';
import '../config.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class SupportScreen extends StatelessWidget {
  final Future<void> Function() onSignOut;
  const SupportScreen({super.key, required this.onSignOut});

  String _url(String path) => '${Config.siteUrl}/${path.replaceFirst(RegExp(r'^/+'), '')}';

  Widget _qr(BuildContext context, String label, String path) {
    if (path.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(children: [
        TagPill(label),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            _url(path),
            width: 220,
            errorBuilder: (c, e, s) => const Text('Could not load the picture.'),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQr = Config.qrphImage.isNotEmpty || Config.instapayImage.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        const HeroBanner(title: 'Support CELEHub', subtitle: 'Free for CE students, always'),
        SoftCard(
          child: Column(
            children: [
              const Text(
                'CELEHub is free for CE students. If it helped you, you can help keep it running. Every bit is optional and appreciated.',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.muted, height: 1.45),
              ),
              if (hasQr && Config.accountName.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Account name: ${Config.accountName}', style: const TextStyle(fontWeight: FontWeight.w700, color: C.text)),
              ],
              _qr(context, 'QR Ph', Config.qrphImage),
              _qr(context, 'InstaPay QR', Config.instapayImage),
            ],
          ),
        ),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(gradient: C.logo, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, color: Colors.white),
            ),
            title: Text(Store.name.isEmpty ? 'Signed in' : Store.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Not you? Sign out to do the quick survey again.', style: TextStyle(fontSize: 12.5)),
            trailing: TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          ),
        ),
      ],
    );
  }
}
