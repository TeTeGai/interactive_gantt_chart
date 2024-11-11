void moveEntireBar({
  required double deltaDX,
  required double startDistance,
  required double distanceFromStart,
  required double widthPerDay,
  required Function(int distanceInDays) onNewDistance,
}) {
  final rawDistance = (startDistance - distanceFromStart) / widthPerDay;
  final newDistanceInDays =
      (deltaDX > 0) ? rawDistance.ceil() : rawDistance.floor();

  onNewDistance(newDistanceInDays);
}
