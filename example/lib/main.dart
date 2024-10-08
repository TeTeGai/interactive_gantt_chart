import 'package:flutter/material.dart';
import 'package:interactive_gantt_chart/interactive_gantt_chart.dart';

import 'dummy_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Text('Hello, Gantt!'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GanttChart<Task>(
                    data: DummyData.data.map((task) {
                      return GanttData<Task>(
                        dateStart: task.start,
                        dateEnd: task.end,
                        data: task,
                        label: task.name,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
