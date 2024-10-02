/// Wrapper Class to be rendered in the Gantt chart
class GanttData<T> {
  final DateTime dateStart;
  final DateTime dateEnd;
  final T data;
  final String label;

  GanttData({
    required this.dateStart,
    required this.dateEnd,
    required this.data,
    required this.label,
  });

  GanttData<T> copyWith({
    DateTime? dateStart,
    DateTime? dateEnd,
    T? data,
    String? label,
  }) {
    return GanttData<T>(
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      data: data ?? this.data,
      label: label ?? this.label,
    );
  }
}
