// ignore: lines_longer_than_80_chars
// ignore_for_file: omit_local_variable_types, public_member_api_docs, library_private_types_in_public_api

import 'dart:async';

import 'package:encryption_benchmarks/key_derivation.dart'
    deferred as key_derivation;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PBKDF2 Benchmark'),
        ),
        body: const BenchmarkBody(),
      ),
    );
  }
}

class BenchmarkBody extends StatefulWidget {
  const BenchmarkBody({super.key});

  @override
  _BenchmarkBodyState createState() => _BenchmarkBodyState();
}

class _BenchmarkBodyState extends State<BenchmarkBody> {
  final _resultsWithIsolate = <int, int>{};
  final _resultsWithoutIsolate = <int, int>{};
  bool _isLoading = false;
  int iterations = 0;

  static Future<int> _deriveKey(int iterations) async {
    await key_derivation.loadLibrary();
    return key_derivation.deriveKey(iterations);
  }

  Future<void> _runBenchmark({required bool runInIsolate}) async {
    setState(() {
      _isLoading = true;
    });

    for (int i = 0; i <= 20000; i += 1000) {
      final clampedI = i <= 0 ? 1 : i;

      setState(() {
        iterations = clampedI;
      });

      if (runInIsolate) {
        // With isolate
        final elapsedMillisecondsWithIsolate =
            await compute(_deriveKey, clampedI);
        setState(() {
          _resultsWithIsolate[clampedI] = elapsedMillisecondsWithIsolate;
        });
      } else {
        // Without isolate
        final elapsedMillisecondsWithoutIsolate = await _deriveKey(clampedI);
        setState(() {
          _resultsWithoutIsolate[clampedI] = elapsedMillisecondsWithoutIsolate;
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      throw UnimplementedError(
        'Not supported on web. TODO: use dart2js to write web worker',
      );
    }

    final lineBarsData = [
      LineChartBarData(
        spots: _resultsWithIsolate.entries
            .map(
              (entry) =>
                  FlSpot(entry.key.toDouble() / 10000, entry.value.toDouble()),
            )
            .toList(),
        isCurved: true,
        color: Colors.red,
        barWidth: 2,
        dotData: FlDotData(show: true),
      ),
      LineChartBarData(
        spots: _resultsWithoutIsolate.entries
            .map(
              (entry) =>
                  FlSpot(entry.key.toDouble() / 10000, entry.value.toDouble()),
            )
            .toList(),
        isCurved: true,
        color: Colors.blue,
        barWidth: 2,
        dotData: FlDotData(show: true),
      ),
    ];

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _runBenchmark(runInIsolate: true),
                  child: const Text('Run Benchmark (Isolate)'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _runBenchmark(runInIsolate: false),
                  child: const Text('Run Benchmark (Main thread)'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.5,
              // height: 450,
              child: LineChart(
                LineChartData(
                  lineBarsData: lineBarsData,
                  minY: 0,
                  maxY: (_resultsWithIsolate.isNotEmpty ||
                          _resultsWithoutIsolate.isNotEmpty)
                      ? (_resultsWithIsolate.values
                              .followedBy(_resultsWithoutIsolate.values)
                              .reduce((a, b) => a > b ? a : b) *
                          1.1)
                      : 100,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('Compute time (ms)'),
                      sideTitles: SideTitles(
                        showTitles: false,
                        getTitlesWidget: (value, _) {
                          final intValue = value.toInt();
                          final readableLabel =
                              '${(intValue / 1000).toStringAsFixed(0)}s';
                          return Text(
                            // intValue == 0 ? '' : intValue.toString(),
                            readableLabel,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Iterations (x10k)',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const Text(
              'Red: With Isolate',
              style: TextStyle(color: Colors.red),
            ),
            const Text(
              'Blue: Without Isolate (Main/UI Thread)',
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
        if (_isLoading)
          ColoredBox(
            color: Colors.black38,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Processing $iterations iterations...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  DateTime dateOfDaysFromNow(int days) {
    /// MODIFY CODE ONLY BELOW THIS LINE

    final now = DateTime.now();

    final startOfToday = DateTime(now.year, now.month, now.day);

    final isFuture = days > 0;

    if (isFuture) {
      return startOfToday.add(Duration(days: days.abs()));
    } else {
      return startOfToday.subtract(Duration(days: days.abs()));
    }

    /// MODIFY CODE ONLY ABOVE THIS LINE
  }
}
