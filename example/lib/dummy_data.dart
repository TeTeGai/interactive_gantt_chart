import 'dart:math';

class DummyData {
  static List<Task> get data {
    int counter = 0;
    final random = Random();

    return List.generate(50, (index) {
      if (index % 2 == 0 && index != 0) {
        counter++;
      }

      // Tạo giờ và phút ngẫu nhiên
      int randomHour = random.nextInt(24); // 0 đến 23
      int randomMinute = random.nextInt(60); // 0 đến 59

      if (index == 0) {
        return Task(
          name: 'Test Short',
          start: DateTime.now().add(Duration(hours: randomHour, minutes: randomMinute)),
          end: DateTime.now().add(Duration( hours: randomHour, minutes: randomMinute)),
        );
      }

      return Task(
        name: 'Task $counter',
        start: DateTime.now().add(Duration(days: counter)),
        end: DateTime.now().add(Duration(days: counter, hours: randomHour, minutes: randomMinute)),
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
