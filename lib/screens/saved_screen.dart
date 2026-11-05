import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Videos you save, and the ones you watch, show up here.', textAlign: TextAlign.center),
            ),
          );
        }
        final List<Widget> items = <Widget>[];
        if (favs.isNotEmpty) {
          items.add(_header(context, 'Saved', null));
          for (final Video v in favs) {
            items.add(VideoCard(video: v));
          }
        }
        if (recents.isNotEmpty) {
          items.add(_header(context, 'Recently watched', () => Store.clearRecents()));
          for (final Video v in recents) {
            items.add(VideoCard(video: v));
          }
        }
        return ListView(children: items);
      },
    );
  }

  Widget _header(BuildContext context, String text, VoidCallback? onClear) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 2),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
          if (onClear != null) TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}
