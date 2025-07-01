import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

import 'package:fleuron/data/store.dart';
import 'package:fleuron/data/entry.dart';

part 'statuses.g.dart';

class StatusesState {
  Set<int> markUnread = {};
  Set<int> markRead = {};
}

@riverpod
class Statuses extends _$Statuses {
  @override
  StatusesState build() => StatusesState();

  void markRead(int entryID) {
    if (!state.markUnread.remove(entryID)) {
      state.markRead.add(entryID);
    }
  }

  void markUnread(int entryID) {
    if (!state.markRead.remove(entryID)) {
      state.markUnread.add(entryID);
    }
  }

  void modifyStatuses(List<Entry> entries) {
    for (final entryID in state.markUnread) {
      entries.firstWhere(
        (entry) => entry.id == entryID,
      ).status = EntryStatus.unread;
    }

    for (final entryID in state.markRead) {
      entries.firstWhere(
        (entry) => entry.id == entryID,
      ).status = EntryStatus.read;
    }
  }

  Future refresh() async {
    final store = await Store.fromPersisted();

    if (store == null) {
      return;
    }

    final url = Uri.https('reader.miniflux.app', '/v1/entries');

    if (state.markUnread.isNotEmpty) {
      await http.put(
        url,
        headers: {'X-Auth-Token': store.token},
        body: json.encode({
          'entry_ids': state.markUnread.toList(),
          'status': 'unread',
        }),
      );

      state.markUnread = {};
    }

    if (state.markRead.isNotEmpty) {
      await http.put(
        url,
        headers: {'X-Auth-Token': store.token},
        body: json.encode({
          'entry_ids': state.markRead.toList(),
          'status': 'read',
        }),
      );

      state.markRead = {};
    }
  }
}
