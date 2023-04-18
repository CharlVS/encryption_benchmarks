import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as enc;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('PBKDF2 Benchmark'),
        ),
        body: BenchmarkBody(),
      ),
    );
  }
}

class BenchmarkBody extends StatefulWidget {
  @override
  _BenchmarkBodyState createState() => _BenchmarkBodyState();
}

class _BenchmarkBodyState extends State<BenchmarkBody> {
  final _results = <int, int>{};
  bool _isLoading = false;

  static Future<int> _deriveKey(int iterations) async {
    final password = 'password';
    final iv = enc.IV.fromLength(8);
    final stopwatch = Stopwatch()..start();
    final key = enc.Key.fromUtf8(password)
        .stretch(32, iterationCount: iterations, salt: iv.bytes);
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _isLoading = true;
    });

    for (int i = 0; i <= 100000; i += 10000) {
      final clampedI = i <= 0 ? 1 : i;
      final elapsedMilliseconds = await compute(_deriveKey, clampedI);
      setState(() {
        _results[clampedI] = elapsedMilliseconds;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.all(16),
          children: [
            ElevatedButton(
              onPressed: _runBenchmark,
              child: Text('Run Benchmark'),
            ),
            ..._results.entries.map(
              (entry) => ListTile(
                title: Text('${entry.key} iterations'),
                trailing: Text('${entry.value} ms'),
              ),
            ),
          ],
        ),
        if (_isLoading)
          Container(
            color: Colors.black38,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Processing ${_results.length * 10000} iterations...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
