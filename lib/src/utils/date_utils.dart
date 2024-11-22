bool isTargetInRange(DateTime target, DateTime origin) {
  return target.isAfter(origin.subtract(const Duration(days: 1))) &&
      target.isBefore(origin.add(const Duration(days: 1)));
}