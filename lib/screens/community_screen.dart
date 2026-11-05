import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';

class CommunityScreen extends StatefulWidget {
  // called when the website says the quick survey must be done again
  final Future<void> Function() onNeedSurvey;
  const CommunityScreen({super.key, required this.onNeedSurvey});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with AutomaticKeepAliveClientMixin {
  List<Comment>? _comments;
  bool _loading = true;
  bool _sending = false;
  int _rating = 5;
  final TextEditingController _text = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await Api.comments();
    if (!mounted) return;
    setState(() {
      _comments = list;
      _loading = false;
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleResult(String? err) async {
    if (err == null) return;
    if (err == 'AUTH') {
      _toast('Please do the quick survey again.');
      await widget.onNeedSurvey();
      return;
    }
    _toast(err);
  }

  Future<void> _send() async {
    final msg = _text.text.trim();
    if (msg.isEmpty || _sending) return;
    setState(() => _sending = true);
    final err = await Api.postComment(msg, rating: _rating);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err == null) {
      _text.clear();
      await _load();
    } else {
      await _handleResult(err);
    }
  }

  Future<void> _reply(Comment c) async {
    final ctl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reply to ${c.name}'),
        content: TextField(controller: ctl, autofocus: true, maxLength: 500, maxLines: 4, minLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(ctl.text.trim()), child: const Text('Reply')),
        ],
      ),
    );
    ctl.dispose();
    if (text == null || text.isEmpty) return;
    final err = await Api.postComment(text, parentId: c.id);
    if (!mounted) return;
    if (err == null) {
      await _load();
    } else {
      await _handleResult(err);
    }
  }

  Widget _stars(int n) {
    final s = StringBuffer();
    for (var i = 0; i < 5; i++) {
      s.write(i < n ? '★' : '☆');
    }
    return Text(s.toString(), style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 14));
  }

  Widget _commentTile(Comment c) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(c.day, style: Theme.of(context).textTheme.bodySmall),
            ]),
            if (c.rating > 0) _stars(c.rating),
            const SizedBox(height: 4),
            Text(c.message),
            for (final r in c.replies)
              Container(
                margin: const EdgeInsets.only(top: 8, left: 10),
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(border: Border(left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(r.message),
                ]),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(onPressed: () => _reply(c), icon: const Icon(Icons.reply, size: 18), label: const Text('Reply')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final list = _comments;
    return Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: list == null
                      ? ListView(children: const [SizedBox(height: 80), Center(child: Text('Could not load comments. Pull down to retry.'))])
                      : list.isEmpty
                          ? ListView(children: const [SizedBox(height: 80), Center(child: Text('No comments yet. Be the first!'))])
                          : ListView.builder(itemCount: list.length, itemBuilder: (c, i) => _commentTile(list[i])),
                ),
        ),
        Material(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  const Text('Rating'),
                  const SizedBox(width: 6),
                  for (var i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () => setState(() => _rating = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(i <= _rating ? Icons.star : Icons.star_border, color: const Color(0xFFF59E0B)),
                      ),
                    ),
                ]),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Write a comment', counterText: '', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
