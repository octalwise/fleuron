import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fleuron/state/entries.dart';

import 'package:fleuron/data/entry.dart';

class EntryView extends ConsumerWidget {
  final int entryID;

  const EntryView({super.key, required this.entryID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.read(entriesProvider.notifier).getEntry(entryID);

    ref.watch(entriesProvider);

    final queryData = MediaQueryData.fromView(View.of(context));

    final scalerData = queryData.copyWith(
      textScaler: const TextScaler.linear(1.2),
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(entry.title, style: Theme.of(context).textTheme.headlineSmall),
              ),
            ),
            MediaQuery(
              data: scalerData,
              child: Html(
                data: entry.content,
                style: {
                  'a': Style(
                    textDecoration: TextDecoration.none,
                  ),
                },
                onLinkTap: (url, attributes, element) {
                  if (url != null) {
                    launchUrl(Uri.parse(url));
                  }
                },
              ),
            ),
          ],
        ),
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
    );
  }
}
