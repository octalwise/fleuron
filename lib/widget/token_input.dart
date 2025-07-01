import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            actions: [
              TextButton(
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
                child: Text('OK'),
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
