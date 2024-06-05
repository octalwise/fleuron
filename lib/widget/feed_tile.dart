import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleuron/state/entries.dart';
import 'package:fleuron/state/feeds.dart';

import 'package:fleuron/data/entry.dart';

import 'package:fleuron/widget/entries_list.dart';

class FeedTile extends ConsumerWidget {
  final int feedID;

  const FeedTile({super.key, required this.feedID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var entries = ref.read(entriesProvider.notifier).fromFeed(feedID);
    var feed    = ref.read(feedsProvider.notifier).getFeed(feedID);

    return Opacity(
      opacity: entries.where(
        (entry) => entry.status == EntryStatus.unread,
      ).isNotEmpty ? 1 : 0.5,

      child: ListTile(
        leading: CircleAvatar(child: Text(feed.title[0])),
        title: Text(feed.title),
        subtitle: Text('${entries.length} Entries'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EntriesList(feedID: feed.id),
            ),
          );
        },
      ),
    );
  }
}
