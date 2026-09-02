import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/trip.dart';
import '../plan/plan_trip_screen.dart';
import 'trip_details_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _tripStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('trips')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Trips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _tripStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load trips.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _emptyTrips(context);
          }

          final trips = docs.map((doc) {
            final data = doc.data();

            final startTimestamp = data['startDate'] as Timestamp?;
            final endTimestamp = data['endDate'] as Timestamp?;

            return Trip(
              id: doc.id,
              userId: data['userId']?.toString() ?? '',
              destination: data['destination']?.toString() ?? '',
              country: data['country']?.toString() ?? '',
              startDate: startTimestamp?.toDate() ?? DateTime.now(),
              endDate: endTimestamp?.toDate() ?? DateTime.now(),
              budget: (data['budget'] as num?)?.toDouble() ?? 0,
              tripType: data['tripType']?.toString() ?? '',
              notes: data['notes']?.toString() ?? '',
              status: data['status']?.toString() ?? 'Upcoming',
            );
          }).toList();

          trips.sort(
            (a, b) => a.startDate.compareTo(b.startDate),
          );

          final upcomingTrips = trips
              .where(
                (trip) => trip.status == 'Upcoming',
              )
              .toList();

          final completedTrips = trips
              .where(
                (trip) => trip.status == 'Completed',
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Upcoming Trips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              if (upcomingTrips.isEmpty)
                const Text(
                  'No upcoming trips.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),

              ...upcomingTrips.map(
                (trip) => _buildTripCard(
                  context,
                  trip,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Past Trips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              if (completedTrips.isEmpty)
                const Text(
                  'No past trips yet.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),

              ...completedTrips.map(
                (trip) => _buildTripCard(
                  context,
                  trip,
                ),
              ),

              const SizedBox(height: 100),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PlanTripScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Trip'),
      ),
    );
  }

  Widget _emptyTrips(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.luggage_outlined,
              size: 80,
              color: AppColors.primary,
            ),

            const SizedBox(height: 20),

            const Text(
              'No trips yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Start planning your first adventure.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PlanTripScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Plan a Trip'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    Trip trip,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailsScreen(
              trip: trip,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.flight_takeoff_rounded,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trip.destination}, ${trip.country}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Rs. ${trip.budget.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}