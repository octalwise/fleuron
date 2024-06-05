import 'dart:io';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:fleuron/state/entries.dart';
import 'package:fleuron/state/feeds.dart';
import 'package:fleuron/state/statuses.dart';

import 'package:fleuron/data/entry.dart';
import 'package:fleuron/data/feed.dart';

part 'store.g.dart';

@JsonSerializable()
class Store {
  final List<Entry> entries;
  final List<Feed>  feeds;
  final DateTime    lastFetched;

  static Future<File> get dataFile async {
    var documentsPath = (await getApplicationDocumentsDirectory()).path;
    return File(path.join(documentsPath, 'data.json'));
  }

  const Store({
    required this.entries,
    required this.feeds,
    required this.lastFetched,
  });

  factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);

  static Future<Store?> fromPersisted() async {
    var file   = await dataFile;
    var exists = await file.exists();

    if (!exists) {
      return null;
    }

    var data = await file.readAsString();
    return Store.fromJson(json.decode(data));
  }

  Future persist() async {
    var file = await dataFile;

    var data = json.encode(toJson());
    file.writeAsString(data);
  }

  Map<String, dynamic> toJson() => _$StoreToJson(this);
}

Future refreshStore(WidgetRef ref) async {
  var store = await Store.fromPersisted();

  var entries = await getEntries(store, ref);
  var feeds   = store != null ? store.feeds : await getFeeds();

  ref.read(entriesProvider.notifier).setEntries(entries);
  ref.read(feedsProvider.notifier).setFeeds(feeds);

  Store(
    entries: entries,
    feeds: feeds,
    lastFetched: DateTime.now(),
  ).persist();
}

Future<List<Entry>> getEntries(Store? store, WidgetRef ref) async {
  var after =
    store == null
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : store.lastFetched;

  var url = Uri.https(
    'reader.miniflux.app', '/v1/entries',
    {
      'limit': '100',
      'changed_after': (after.millisecondsSinceEpoch / 1000).toStringAsFixed(0),
      'direction': 'desc',
    },
  );

  var token = const String.fromEnvironment('TOKEN');

  var res  = await http.get(url, headers: {'X-Auth-Token': token});
  var data = json.decode(utf8.decode(res.bodyBytes))['entries'];

  var entries = List<Entry>.from(
    data.map((data) => Entry.fromJson(data)),
  );

  var curEntries = ref.read(entriesProvider);

  if (curEntries.isNotEmpty || store != null) {
    var ids = entries.map((entry) => entry.id).toSet();

    var oldEntries =
      curEntries.isNotEmpty ? curEntries : store!.entries;

    for (final entry in oldEntries) {
      if (!ids.contains(entry.id)) {
        entries.add(entry);
      }
    }
  }

  ref.read(statusesProvider.notifier).modifyStatuses(entries);

  return entries;
}

Future<List<Feed>> getFeeds() async {
  var token = const String.fromEnvironment('TOKEN');

  var res = await http.get(
    Uri.https('reader.miniflux.app', '/v1/feeds'),
    headers: {'X-Auth-Token': token},
  );

  var data = json.decode(utf8.decode(res.bodyBytes));
  return List<Feed>.from(data.map((data) => Feed.fromJson(data)));
}
