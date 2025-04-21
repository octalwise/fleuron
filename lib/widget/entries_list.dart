import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleuron/state/entries.dart';
import 'package:fleuron/state/feeds.dart';

import 'package:fleuron/widget/entry_view.dart';

import 'package:fleuron/data/entry.dart';

class EntriesList extends ConsumerWidget {
  final int feedID;

  const EntriesList({super.key, required this.feedID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.read(entriesProvider.notifier).fromFeed(feedID);
    final feed    = ref.read(feedsProvider.notifier).getFeed(feedID);

    ref.watch(entriesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(feed.title),
              titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: entries.length,
              (context, index) {
                Entry entry = entries[index];

                return Opacity(
                  opacity: entry.status == EntryStatus.unread ? 1 : 0.5,
                  child: ListTile(
                    leading: CircleAvatar(child: entry.starred ? Icon(Icons.star) : Text(entry.feed.title[0])),
                    title: Text(entry.title),
                    subtitle: Text(entry.feed.title),
                    onTap: () {
                      ref.read(entriesProvider.notifier).markRead(entry.id);

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EntryView(entryID: entry.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
