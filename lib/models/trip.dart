import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Convert a Firestore document into a Trip object.
  factory Trip.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError(
        'Trip document ${document.id} does not contain data.',
      );
    }

    return Trip(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      country: data['country'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      tripType: data['tripType'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      status: data['status'] as String? ?? '',
    );
  }
}