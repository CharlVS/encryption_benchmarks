import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:fl_chart/fl_chart.dart';

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
  final _resultsWithIsolate = <int, int>{};
  final _resultsWithoutIsolate = <int, int>{};
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

      // With isolate
      final elapsedMillisecondsWithIsolate =
          await compute(_deriveKey, clampedI);
      setState(() {
        _resultsWithIsolate[clampedI] = elapsedMillisecondsWithIsolate;
      });

      // Without isolate
      final elapsedMillisecondsWithoutIsolate = await _deriveKey(clampedI);
      setState(() {
        _resultsWithoutIsolate[clampedI] = elapsedMillisecondsWithoutIsolate;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lineBarsData = [
      LineChartBarData(
        spots: _resultsWithIsolate.entries
            .map((entry) =>
                FlSpot(entry.key.toDouble() / 10000, entry.value.toDouble()))
            .toList(),
        isCurved: true,
        color: Colors.red,
        barWidth: 2,
        dotData: FlDotData(show: true),
      ),
      LineChartBarData(
        spots: _resultsWithoutIsolate.entries
            .map((entry) =>
                FlSpot(entry.key.toDouble() / 10000, entry.value.toDouble()))
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
          padding: EdgeInsets.all(16),
          children: [
            ElevatedButton(
              onPressed: _runBenchmark,
              child: Text('Run Benchmark'),
            ),
            SizedBox(height: 16),
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
                          axisNameWidget: Text('Compute time (seconds)'),
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final intValue = value.toInt();
                              final readableLabel =
                                  (intValue / 1000).toStringAsFixed(0) + 's';
                              return Text(
                                // intValue == 0 ? '' : intValue.toString(),
                                readableLabel,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                          )),
                      bottomTitles: AxisTitles(
                        axisNameWidget: Text(
                          'Iterations (x10k)',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          // getTitles: (value) {
                          //   final intValue = (value * 10000).toInt();
                          //   return intValue == 0 ? '' : intValue.toString();
                          // },
                          getTitlesWidget: (value, _) {
                            final intValue = (value * 10000).toInt();
                            final readableLabel =
                                (intValue / 1000).toStringAsFixed(0) + '';
                            return Text(
                              // intValue == 0 ? '' : intValue.toString(),
                              readableLabel,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      )),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            Text(
              'Red: With Isolate',
              style: TextStyle(color: Colors.red),
            ),
            Text(
              'Blue: Without Isolate',
              style: TextStyle(color: Colors.blue),
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
                    'Processing ${_resultsWithIsolate.length * 10000} iterations...',
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
