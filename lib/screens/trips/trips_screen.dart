import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/trip.dart';
import '../plan/plan_trip_screen.dart';
import 'trip_details_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final List<Trip> _trips = [
    Trip(
      destination: 'Tokyo',
      country: 'Japan',
      startDate: '12 Dec 2026',
      endDate: '18 Dec 2026',
      budget: 'Rs. 120,000',
      status: 'Upcoming',
    ),
    Trip(
      destination: 'Rome',
      country: 'Italy',
      startDate: '05 Feb 2027',
      endDate: '10 Feb 2027',
      budget: 'Rs. 150,000',
      status: 'Upcoming',
    ),
    Trip(
      destination: 'Singapore',
      country: 'Singapore',
      startDate: '10 May 2026',
      endDate: '14 May 2026',
      budget: 'Rs. 90,000',
      status: 'Completed',
    ),
  ];

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
      body: ListView(
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

          ..._trips
              .where((trip) => trip.status == 'Upcoming')
              .map((trip) => _buildTripCard(trip)),

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

          ..._trips
              .where((trip) => trip.status == 'Completed')
              .map((trip) => _buildTripCard(trip)),

          const SizedBox(height: 100),
        ],
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

  Widget _buildTripCard(Trip trip) {
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
                color: AppColors.primary.withValues(alpha: 0.10),
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
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${trip.startDate} - ${trip.endDate}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trip.budget,
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
}