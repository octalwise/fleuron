import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:http/http.dart' as http;
import 'package:http_auth/http_auth.dart' as http_auth;

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
  final String? api;
  final String token;

  final String? username;
  final String? password;

  final List<Entry> entries;
  final List<Feed> feeds;

  final DateTime lastFetched;

  static Future<File> get dataFile async {
    final dir = await getApplicationDocumentsDirectory();
    final docs = dir.path;

    return File(path.join(docs, 'data.json'));
  }

  const Store({
    required this.api,
    required this.token,

    required this.username,
    required this.password,

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
    await file.writeAsString(data);
  }

  Map<String, dynamic> toJson() => _$StoreToJson(this);
}

class Meta {
  final String api;
  final String token;
  final String? username;
  final String? password;

  late final http.Client client =
    username != null && password != null
      ? http_auth.NegotiateAuthClient(username!, password!)
      : http.Client();

  Meta({
    required this.api,
    required this.token,
    required this.username,
    required this.password,
  });

  Future<http.Response> get(String path, {Map<String, String>? query}) async {
    Uri url = Uri.parse(api).resolve(path).replace(queryParameters: query);
    return client.get(url, headers: {'X-Auth-Token': token});
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final url = Uri.parse(api).resolve(path);
    return client.put(url, headers: {'X-Auth-Token': token}, body: body);
  }
}

Future loadPersisted(WidgetRef ref) async {
  final store = await Store.fromPersisted();

  if (store == null) {
    return;
  }

  ref.read(entriesProvider.notifier).setEntries(store.entries);
  ref.read(feedsProvider.notifier).setFeeds(store.feeds);
}

Future refreshStore(
  BuildContext context,
  WidgetRef ref,
  {Meta? update}
) async {
  final store = await Store.fromPersisted();
  final token = update?.token ?? store?.token;

  if (token == null) {
    showTokenInput(context, ref, dismissable: false);
    return;
  }

  final api = update?.api ?? store?.api ?? 'https://reader.miniflux.app';

  final username = update != null ? update.username : store?.username;
  final password = update != null ? update.password : store?.password;

  final meta = Meta(
    api: api,
    token: token,
    username: username,
    password: password
  );

  final entries = await getEntries(store, meta, ref);
  final feeds = await getFeeds(meta);

  ref.read(entriesProvider.notifier).setEntries(entries);
  ref.read(feedsProvider.notifier).setFeeds(feeds);

  await Store(
    api: api,
    token: token,
    username: username,
    password: password,
    entries: entries,
    feeds: feeds,
    lastFetched: DateTime.now(),
  ).persist();
}

Future<List<Entry>> getEntries(Store? store, Meta meta, WidgetRef ref) async {
  final after =
    store == null
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : store.lastFetched;

  var entries = <Entry>[];

  try {
    final res = await meta.get('v1/entries', query: {
      'limit': '500',
      'changed_after': (after.millisecondsSinceEpoch / 1000).toStringAsFixed(0),
      'direction': 'desc',
    });
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

Future<List<Feed>> getFeeds(Meta meta) async {
  final res = await meta.get('v1/feeds');
  final data = json.decode(utf8.decode(res.bodyBytes));

  return List<Feed>.from(data.map((data) => Feed.fromJson(data)));
}
