class DummyData {
  static List<Task> get data {
    int counter = 0;

    return List.generate(50, (index) {
      if (index % 2 == 0 && index != 0) {
        counter++;
      }
      return Task(
        name: 'Task Task task $index',
        start: DateTime(2024, 10, 1).add(Duration(days: counter)),
        end: DateTime.now().add(Duration(days: counter + 10)),
      );
    });
  }
}

class Task {
  final String name;
  final DateTime start;
  final DateTime end;

  const Task({
    required this.name,
    required this.start,
    required this.end,
  });
}
