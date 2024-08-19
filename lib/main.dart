import 'package:flutter/material.dart';

import 'package:fleuron/widget/home.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(
  const ProviderScope(child: Home()),
);
