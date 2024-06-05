import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:fleuron/state/entries.dart';

import 'package:fleuron/data/entry.dart';

class EntryView extends ConsumerWidget {
  final int entryID;

  const EntryView({super.key, required this.entryID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var entry = ref.read(entriesProvider.notifier).getEntry(entryID);

    ref.watch(entriesProvider);

    var queryData = MediaQueryData.fromView(View.of(context));

    var scalerData = queryData.copyWith(
      textScaler: const TextScaler.linear(1.2),
    );

    return MediaQuery(
      data: scalerData,
      child: Scaffold(
        appBar: AppBar(title: Text(entry.title)),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(child: Html(data: entry.content)),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(
            entry.status == EntryStatus.unread
              ? Icons.circle
              : Icons.circle_outlined,
          ),
          onPressed: () {
            ref.read(entriesProvider.notifier).toggleRead(entry.id);
          },
        ),
      )
    );
  }
}
