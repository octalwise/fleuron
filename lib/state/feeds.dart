import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fleuron/data/feed.dart';

part 'feeds.g.dart';

@riverpod
class Feeds extends _$Feeds {
  @override
  List<Feed> build() => [];

  void setFeeds(List<Feed> feeds) {
    state = feeds;
  }

  Feed getFeed(int feedID) {
    if (feedID == -1) {
      return Feed(id: -1, title: "All");
    } else {
      return state.firstWhere((feed) => feed.id == feedID);
    }
  }
}
