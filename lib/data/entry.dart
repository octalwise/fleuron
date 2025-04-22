import 'package:json_annotation/json_annotation.dart';

import 'package:fleuron/data/feed.dart';

part 'entry.g.dart';

enum EntryStatus {
  unread,
  read,
  removed,
}

@JsonSerializable()
class Entry {
  final int id;
  final String title;
  final String? url;
  final String content;
  final bool starred;
  EntryStatus status;
  final Feed feed;

  @JsonKey(name: 'published_at')
  final DateTime publishedAt;

  Entry({
    required this.id,
    required this.title,
    required this.url,
    required this.content,
    required this.starred,
    required this.status,
    required this.feed,
    required this.publishedAt,
  });

  factory Entry.fromJson(Map<String, dynamic> json) => _$EntryFromJson(json);

  Map<String, dynamic> toJson() => _$EntryToJson(this);
}
