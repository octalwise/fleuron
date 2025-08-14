import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fleuron/data/entry.dart';

import 'package:fleuron/state/entries.dart';

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
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: BackButton(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  child: Text(entry.title, style: Theme.of(context).textTheme.headlineSmall),
                  onTap: () {
                    if (entry.url != null) {
                      launchUrl(Uri.parse(entry.url!));
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: MediaQuery(
                data: scalerData,
                child: Html(
                  data: entry.content,
                  style: {
                    'a': Style(
                      textDecoration: TextDecoration.none,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  },
                  onLinkTap: (url, attributes, element) {
                    if (url != null) {
                      launchUrl(Uri.parse(url));
                    }
                  },
                ),
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
