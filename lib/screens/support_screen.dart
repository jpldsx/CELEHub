import 'package:flutter/material.dart';
import '../config.dart';
import '../store.dart';

class SupportScreen extends StatelessWidget {
  final Future<void> Function() onSignOut;
  const SupportScreen({super.key, required this.onSignOut});

  String _url(String path) => '${Config.siteUrl}/${path.replaceFirst(RegExp(r'^/+'), '')}';

  Widget _qr(BuildContext context, String label, String path) {
    if (path.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Image.network(
          _url(path),
          width: 220,
          errorBuilder: (c, e, s) => const Text('Could not load the picture.'),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQr = Config.qrphImage.isNotEmpty || Config.instapayImage.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Support CELEHub', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'CELEHub is free for CE students. If it helped you, you can help keep it running. Every bit is optional and appreciated.',
                  textAlign: TextAlign.center,
                ),
                if (hasQr && Config.accountName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Account name: ${Config.accountName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
                _qr(context, 'QR Ph', Config.qrphImage),
                _qr(context, 'InstaPay QR', Config.instapayImage),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(Store.name.isEmpty ? 'Signed in' : Store.name),
            subtitle: const Text('Not you? Sign out to do the quick survey again.'),
            trailing: TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          ),
        ),
      ],
    );
  }
}
