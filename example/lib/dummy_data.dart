class DummyData {
  static List<Task> get data {
    int counter = 0;

    return List.generate(50, (index) {
      if (index % 2 == 0 && index != 0) {
        counter++;
      }

      if (index == 0) {
        return Task(
          name: 'Test Short',
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(days: 3)),
        );
      }

      return Task(
        name: 'Task $index',
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
