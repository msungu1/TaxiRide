class Ride {
  final String place;
  final String dateTime;
  final String fare;
  final bool cancelled;

  Ride({
    required this.place,
    required this.dateTime,
    required this.fare,
    this.cancelled = false,
  });
}
