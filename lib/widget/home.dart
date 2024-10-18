import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'package:fleuron/state/statuses.dart';
import 'package:fleuron/widget/feeds_list.dart';
import 'package:fleuron/data/store.dart';

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    refreshStore(ref);
    ref.read(statusesProvider.notifier).refresh();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          themeMode: ThemeMode.system,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: lightDynamic,
            navigationBarTheme: NavigationBarThemeData(
              surfaceTintColor: lightDynamic?.surfaceTint
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: darkDynamic,
            navigationBarTheme: NavigationBarThemeData(
              surfaceTintColor: darkDynamic?.surfaceTint
            ),
          ),

          home: const FeedsList(),
        );
      },
    );
  }
}
