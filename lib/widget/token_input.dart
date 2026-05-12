import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:http/http.dart' as http;
import 'package:http_auth/http_auth.dart' as http_auth;

import 'package:fleuron/data/store.dart';

Future showTokenInput(BuildContext context, WidgetRef ref, {bool? dismissable}) async {
  final store = await Store.fromPersisted();

  final apiCtrl = TextEditingController(
    text: store?.api ?? 'https://reader.miniflux.app',
  );
  final tokenCtrl = TextEditingController(
    text: store?.token ?? '',
  );

  final usernameCtrl = TextEditingController(
    text: store?.username ?? '',
  );
  final passwordCtrl = TextEditingController(
    text: store?.password ?? '',
  );

  String? username;
  String? password;

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.help_outline_rounded),
                    onPressed: () => showAboutDialog(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.key_rounded),
                    onPressed: () => showAuthInput(context, store, usernameCtrl, passwordCtrl, (un, pw) {
                      username = un;
                      password = pw;
                    }),
                  ),
                ],
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () async {
                  final api = apiCtrl.text.trim();
                  final verified = api.isNotEmpty && await verifyAPI(api, username, password);

                  setState(() {
                    apiErr = verified ? null : 'Invalid API.';
                    tokenErr = null;
                  });

                  if (!verified) {
                    return;
                  }

                  final token = tokenCtrl.text.trim();

                  final meta = Meta(
                    api: api,
                    token: token,
                    username: username,
                    password: password
                  );

                  if (token.isNotEmpty && await verifyToken(meta)) {
                    refreshStore(context, ref, update: meta);
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

Future<bool> verifyAPI(String api, String? username, String? password) async {
  try {
    final client =
      username != null && password != null
        ? http_auth.NegotiateAuthClient(username, password)
        : http.Client();

    final url = Uri.parse(api).resolve('readiness');
    final res = await client.get(url);

    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<bool> verifyToken(Meta meta) async {
  try {
    final res = await meta.get('v1/me');

    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void showAuthInput(
  BuildContext context,
  Store? store,
  TextEditingController usernameCtrl,
  TextEditingController passwordCtrl,
  void Function(String?, String?) callback,
) async {
  showDialog(
    context: context,
    builder: (context) {
      String? usernameErr;
      String? passwordErr;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter authentication'),
                Text('(optional)', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 6),
                SizedBox(
                  width: double.maxFinite,
                  child: TextField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      errorText: usernameErr,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: double.maxFinite,
                  child: TextField(
                    controller: passwordCtrl,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      errorText: passwordErr,
                    ),
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                child: Text('Clear'),
                onPressed: () async {
                  usernameCtrl.text = '';
                  passwordCtrl.text = '';

                  callback(null, null);
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () async {
                  final username = usernameCtrl.text.trim();
                  final password = passwordCtrl.text.trim();

                  setState(() {
                    usernameErr = username.isEmpty ? 'Invalid username.' : null;
                    passwordErr = password.isEmpty ? 'Invalid password.' : null;
                  });
                  if (username.isEmpty || password.isEmpty) {
                    return;
                  }

                  callback(username, password);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
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
