import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'package:fleuron/widget/feeds_list.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return MaterialApp(
            themeMode: ThemeMode.system,
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: lightDynamic,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: darkDynamic,
            ),

            home: const FeedsList(),
          );
        },
      ),
    );
  }
}
