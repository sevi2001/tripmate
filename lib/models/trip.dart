class Trip {
  final String id;
  final String userId;
  final String destination;
  final String country;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final String tripType;
  final String notes;
  final String status;

  Trip({
    required this.id,
    required this.userId,
    required this.destination,
    required this.country,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.tripType,
    required this.notes,
    required this.status,
  });
}