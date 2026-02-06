import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:http/http.dart' as http;

import 'package:fleuron/data/store.dart';

Future showTokenInput(BuildContext context, WidgetRef ref, {bool? dismissable}) async {
  final store = await Store.fromPersisted();

  final apiCtrl = TextEditingController(
    text: store?.api ?? 'https://reader.miniflux.app',
  );
  final tokenCtrl = TextEditingController(
    text: store?.token ?? '',
  );

  showDialog(
    context: context,
    barrierDismissible: dismissable ?? true,
    builder: (context) {
      String? apiErr;
      String? tokenErr;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Enter Miniflux details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 6),
                SizedBox(
                  width: double.maxFinite,
                  child: TextField(
                    controller: apiCtrl,
                    decoration: InputDecoration(
                      labelText: 'API',
                      border: OutlineInputBorder(),
                      errorText: apiErr,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: double.maxFinite,
                  child: TextField(
                    controller: tokenCtrl,
                    decoration: InputDecoration(
                      labelText: 'Token',
                      border: OutlineInputBorder(),
                      errorText: tokenErr,
                    ),
                  ),
                ),
              ],
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
                  final api = apiCtrl.text.trim();
                  final verified = api.isNotEmpty && await verifyAPI(api);

                  setState(() {
                    apiErr = verified ? null : 'Invalid API.';
                    tokenErr = null;
                  });

                  if (!verified) {
                    return;
                  }

                  final token = tokenCtrl.text.trim();

                  if (token.isNotEmpty && await verifyToken(api, token)) {
                    refreshStore(context, ref, api: api, token: token);
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      tokenErr = 'Invalid token.';
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

Future<bool> verifyAPI(String api) async {
  try {
    final url = Uri.parse(api).resolve('readiness');
    final res = await http.get(url);

    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<bool> verifyToken(String api, String token) async {
  try {
    final url = Uri.parse(api).resolve('v1/me');
    final res = await http.get(url, headers: {'X-Auth-Token': token});

    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void showAboutDialog(BuildContext context) {
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
