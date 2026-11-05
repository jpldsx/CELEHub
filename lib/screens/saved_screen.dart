import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../widgets.dart';
import 'video_list_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Store.changes,
      builder: (c, _, w) {
        final favs = Store.favorites();
        final recents = Store.recents();
        if (favs.isEmpty && recents.isEmpty) {
          return const EmptyState(icon: Icons.bookmark_border_rounded, text: 'Videos you save, and the ones you watch, show up here.');
        }
        final List<Widget> items = <Widget>[
          const HeroBanner(title: 'Your Library', subtitle: 'Saved and recently watched'),
        ];
        if (favs.isNotEmpty) {
          items.add(const SectionTitle('Saved'));
          for (final Video v in favs) {
            items.add(VideoCard(video: v));
          }
        }
        if (recents.isNotEmpty) {
          items.add(SectionTitle('Recently watched', trailing: TextButton(onPressed: () => Store.clearRecents(), child: const Text('Clear'))));
          for (final Video v in recents) {
            items.add(VideoCard(video: v));
          }
        }
        return ListView(padding: const EdgeInsets.only(bottom: 12), children: items);
      },
    );
  }
}
