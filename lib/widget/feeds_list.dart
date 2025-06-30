import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleuron/state/entries.dart';
import 'package:fleuron/state/feeds.dart';
import 'package:fleuron/state/current_tab.dart';
import 'package:fleuron/state/statuses.dart';

import 'package:fleuron/widget/entries_list.dart';

import 'package:fleuron/data/store.dart';
import 'package:fleuron/data/feed.dart';
import 'package:fleuron/data/entry.dart';

class FeedsList extends ConsumerWidget {
  const FeedsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int currentTab = ref.watch(currentTabProvider);
    List<Feed> feeds = ref.watch(feedsProvider);

    ref.watch(entriesProvider);
    ref.watch(statusesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await refreshStore(ref);
          await ref.read(statusesProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 150,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Feeds'),
                titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              ),
            ),
            SliverList.builder(
              itemCount: feeds.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.tonal(
                      child: Text(
                        'All Entries (${ref.read(entriesProvider.notifier).fromFeed(-1).length})',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EntriesList(feedID: -1),
                          ),
                        );
                      },
                    ),
                  );
                }

                Feed feed = feeds[index - 1];
                return FeedTile(feedID: feed.id);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).selectTab(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_rounded),
            label: 'Unread',
          ),
          NavigationDestination(
            icon: Icon(Icons.notes),
            label: 'All',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_rounded),
            label: 'Starred',
          ),
        ],
      ),
    );
  }
}

class FeedTile extends ConsumerWidget {
  final int feedID;

  const FeedTile({super.key, required this.feedID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.read(feedsProvider.notifier).getFeed(feedID);
    final entries = ref.read(entriesProvider.notifier).fromFeed(feedID);

    final anyUnread = entries.where(
      (entry) => entry.status == EntryStatus.unread,
    ).isNotEmpty;

    return Opacity(
      opacity: anyUnread ? 1 : 0.5,
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
