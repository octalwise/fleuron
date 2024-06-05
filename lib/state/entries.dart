import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fleuron/state/statuses.dart';
import 'package:fleuron/state/current_tab.dart';

import 'package:fleuron/data/entry.dart';

part 'entries.g.dart';

@riverpod
class Entries extends _$Entries {
  @override
  List<Entry> build() => [];

  List<Entry> get tabEntries {
    switch (ref.read(currentTabProvider)) {
    case 0:
      return state.where(
        (entry) => entry.status == EntryStatus.unread,
      ).toList();

    case 1:
      return state;

    case 2:
      return state.where((entry) => entry.starred).toList();

    default:
      return [];
    }
  }

  void setEntries(List<Entry> entries) {
    state = entries;
    state.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  }

  Entry getEntry(int entryID) {
    return state.firstWhere((entry) => entry.id == entryID);
  }

  List<Entry> fromFeed(int feedID) {
    if (feedID == -1) {
      return tabEntries;
    } else {
      return tabEntries.where((entry) => entry.feed.id == feedID).toList();
    }
  }

  void toggleRead(int entryID) {
    var entry = state.firstWhere((entry) => entry.id == entryID);

    entry.status =
      entry.status == EntryStatus.unread
        ? EntryStatus.read
        : EntryStatus.unread;

    var statuses = ref.read(statusesProvider.notifier);

    if (entry.status == EntryStatus.unread) {
      statuses.markUnread(entry.id);
    } else {
      statuses.markRead(entry.id);
    }

    state = [...state];
  }

  void markRead(int entryID) {
    var entry = state.firstWhere((entry) => entry.id == entryID);

    entry.status = EntryStatus.read;
    ref.read(statusesProvider.notifier).markRead(entry.id);

    state = [...state];
  }
}
