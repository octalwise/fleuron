import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:http/http.dart' as http;

import 'package:fleuron/data/store.dart';

Future showTokenInput(BuildContext context, WidgetRef ref, {bool? dismissable}) async {
  final store = await Store.fromPersisted();
  final controller = TextEditingController(
    text: store?.token ?? '',
  );

  showDialog(
    context: context,
    barrierDismissible: dismissable ?? true,
    builder: (context) {
      String? error;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Enter Miniflux token'),
            content: SizedBox(
              width: double.maxFinite,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Token',
                  border: OutlineInputBorder(),
                  errorText: error,
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              IconButton(
                icon: Icon(Icons.help_outline_rounded),
                onPressed: () => showAboutDialog(context),
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () async {
                  final token = controller.text.trim();

                  if (token.isNotEmpty && await verifyToken(token)) {
                    refreshStore(context, ref, token: token);
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      error = 'Invalid token.';
                    });
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<bool> verifyToken(String token) async {
  final url = Uri.https('reader.miniflux.app', '/v1/me');
  final res = await http.get(url, headers: {'X-Auth-Token': token});

  return res.statusCode == 200;
}

showAboutDialog(BuildContext context) {
  final linkStyle =
    Theme.of(context).textTheme.bodyLarge!.copyWith(
      color: Theme.of(context).colorScheme.primary,
    );

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('About'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                child: Text('fleuron@octalwise.com', style: linkStyle),
                onTap: () {
                  launchUrl(Uri.parse('mailto:fleuron@octalwise.com'));
                },
              ),
              GestureDetector(
                child: Text('https://octalwise.com/fleuron', style: linkStyle),
                onTap: () {
                  launchUrl(Uri.parse('https://octalwise.com/fleuron'));
                },
              ),
              SizedBox(height: 8),
              Text(
                '© Octalwise LLC',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
