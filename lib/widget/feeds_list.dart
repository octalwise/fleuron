import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleuron/state/entries.dart';
import 'package:fleuron/state/feeds.dart';
import 'package:fleuron/state/current_tab.dart';
import 'package:fleuron/state/statuses.dart';

import 'package:fleuron/widget/entries_list.dart';
import 'package:fleuron/widget/feed_tile.dart';

import 'package:fleuron/data/store.dart';
import 'package:fleuron/data/feed.dart';

class FeedsList extends ConsumerWidget {
  const FeedsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Feed> feeds = ref.watch(feedsProvider);
    int currentTab   = ref.watch(currentTabProvider);

    ref.watch(entriesProvider);
    ref.watch(statusesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feeds')),
      body: ListView.separated(
        itemCount: feeds.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EntriesList(feedID: -1),
                    ),
                  );
                },
                child: Text(
                  'All Entries (${ref.read(entriesProvider.notifier).fromFeed(-1).length})',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          Feed feed = feeds[index - 1];

          return FeedTile(feedID: feed.id);
        },
        separatorBuilder: (context, index) {
          return const Divider(height: 1);
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () {
          refreshStore(ref);
          ref.read(statusesProvider.notifier).refresh();
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).selectTab(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Unread'
          ),
          NavigationDestination(
            icon: Icon(Icons.notes),
            label: 'All'
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Starred'
          ),
        ],
      ),
    );
  }
}
