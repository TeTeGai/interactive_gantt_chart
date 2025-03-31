enum GanttMode {
  day('Day'),
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  ;

  final String name;
  const GanttMode(this.name);
}
