#!/usr/bin/env dart
import 'dart:io';

import 'package:completion/generate.dart';

void main(List<String> arguments) {
  try {
    print(generateCompletionScript(arguments));
  } catch (e) {
    print(e);
    exit(1);
  }
}
