import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:http/http.dart' as http;

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:json_annotation/json_annotation.dart';

import 'package:fleuron/data/entry.dart';
import 'package:fleuron/data/feed.dart';

import 'package:fleuron/state/entries.dart';
import 'package:fleuron/state/feeds.dart';
import 'package:fleuron/state/statuses.dart';

import 'package:fleuron/widget/token_input.dart';

part 'store.g.dart';

@JsonSerializable()
class Store {
  final String token;
  final String? api;

  final List<Entry> entries;
  final List<Feed> feeds;

  final DateTime lastFetched;

  static Future<File> get dataFile async {
    final dir = await getApplicationDocumentsDirectory();
    final docs = dir.path;

    return File(path.join(docs, 'data.json'));
  }

  const Store({
    required this.token,
    required this.api,
    required this.entries,
    required this.feeds,
    required this.lastFetched,
  });

  factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);

  static Future<Store?> fromPersisted() async {
    final file = await dataFile;
    final exists = await file.exists();

    if (!exists) {
      return null;
    }

    final data = await file.readAsString();
    return Store.fromJson(json.decode(data));
  }

  Future persist() async {
    final data = json.encode(toJson());

    final file = await dataFile;
    file.writeAsString(data);
  }

  Map<String, dynamic> toJson() => _$StoreToJson(this);
}

Future persistedState(WidgetRef ref) async {
  final store = await Store.fromPersisted();

  if (store == null) {
    return;
  }

  ref.read(entriesProvider.notifier).setEntries(store.entries);
  ref.read(feedsProvider.notifier).setFeeds(store.feeds);
}

Future refreshStore(BuildContext context, WidgetRef ref, {String? api, String? token}) async {
  final store = await Store.fromPersisted();
  final tok = token ?? store?.token;

  if (tok == null) {
    showTokenInput(context, ref, dismissable: false);
    return;
  }

  final url = api ?? store?.api ?? 'https://reader.miniflux.app';

  final entries = await getEntries(store, url, tok, ref);
  final feeds = await getFeeds(url, tok);

  ref.read(entriesProvider.notifier).setEntries(entries);
  ref.read(feedsProvider.notifier).setFeeds(feeds);

  Store(
    api: url,
    token: tok,
    entries: entries,
    feeds: feeds,
    lastFetched: DateTime.now(),
  ).persist();
}

Future<List<Entry>> getEntries(Store? store, String api, String token, WidgetRef ref) async {
  final after =
    store == null
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : store.lastFetched;

  final url = Uri.parse(api).resolve('v1/entries').replace(
    queryParameters: {
      'limit': '500',
      'changed_after': (after.millisecondsSinceEpoch / 1000).toStringAsFixed(0),
      'direction': 'desc',
    },
  );

  var entries = <Entry>[];

  try {
    final res = await http.get(url, headers: {'X-Auth-Token': token});
    final data = json.decode(utf8.decode(res.bodyBytes))['entries'];

    entries = List<Entry>.from(
      data.map((data) => Entry.fromJson(data)),
    );
  } catch (_) {}

  final curEntries = ref.read(entriesProvider);

  if (curEntries.isNotEmpty || store != null) {
    final ids = entries.map((entry) => entry.id).toSet();

    final oldEntries =
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

Future<List<Feed>> getFeeds(String api, String token) async {
  final res = await http.get(
    Uri.parse(api).resolve('v1/feeds'),
    headers: {'X-Auth-Token': token},
  );

  final data = json.decode(utf8.decode(res.bodyBytes));
  return List<Feed>.from(data.map((data) => Feed.fromJson(data)));
}
