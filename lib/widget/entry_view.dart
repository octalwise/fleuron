import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fleuron/data/entry.dart';

import 'package:fleuron/state/entries.dart';

class EntryView extends ConsumerStatefulWidget {
  final int entryID;

  const EntryView({super.key, required this.entryID});

  @override
  EntryViewState createState() => EntryViewState();
}

class EntryViewState extends ConsumerState<EntryView> {
  final controller = ScrollController();
  var showFAB = true;

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      final dir = controller.position.userScrollDirection;
      final show = dir == ScrollDirection.forward;

      if (dir != ScrollDirection.idle && showFAB != show) {
        setState(() => showFAB = show);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.read(entriesProvider.notifier).getEntry(widget.entryID);
    ref.watch(entriesProvider);

    final queryData = MediaQueryData.fromView(View.of(context));

    final scalerData = queryData.copyWith(
      textScaler: const TextScaler.linear(1.2),
    );

    return Scaffold(
      body: SingleChildScrollView(
        controller: controller,
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
                  extensions: [
                    OnImageTapExtension(
                      onImageTap: (url, attributes, element) {
                        if (url != null) {
                          launchUrl(Uri.parse(url));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: showFAB ? Offset.zero : Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: showFAB ? 1 : 0,
          child: FloatingActionButton(
            child: Icon(
              entry.status == EntryStatus.unread
                ? Icons.circle
                : Icons.circle_outlined,
            ),
            onPressed: () {
              ref.read(entriesProvider.notifier).toggleRead(entry.id);
            },
          ),
        ),
      ),
    );
  }
}
