import 'dart:async';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;

Future<int> deriveKey(int iterations) async {
  final password = 'password';
  final iv = enc.IV.fromLength(8);
  final stopwatch = Stopwatch()..start();
  final key = enc.Key.fromUtf8(password)
      .stretch(32, iterationCount: iterations, salt: iv.bytes);
  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}
