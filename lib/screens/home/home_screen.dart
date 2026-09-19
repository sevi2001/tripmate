import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/utils/trip_image_helper.dart';
import '../../models/trip.dart';
import '../trips/trip_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your trips.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('trips')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
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
                    'Unable to load your trips.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final List<Trip> trips = snapshot.data?.docs
                    .map((document) => Trip.fromFirestore(document))
                    .toList() ??
                <Trip>[];

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final upcomingTrips = trips.where((trip) {
              return !trip.endDate.isBefore(today);
            }).toList();

            upcomingTrips.sort(
              (a, b) => a.startDate.compareTo(b.startDate),
            );

            final Trip? nextTrip =
                upcomingTrips.isEmpty ? null : upcomingTrips.first;

            final countryCount = trips
                .map((trip) => trip.country.trim().toLowerCase())
                .where((country) => country.isNotEmpty)
                .toSet()
                .length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  const SizedBox(height: 28),

                  _buildUpcomingTrip(context, nextTrip),

                  const SizedBox(height: 30),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildQuickActions(),

                  const SizedBox(height: 30),

                  const Text(
                    'Travel Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildStats(
                    tripCount: trips.length,
                    countryCount: countryCount,
                    upcomingCount: upcomingTrips.length,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back 👋',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ready for your next adventure?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // UPCOMING TRIP — ORIGINAL GRADIENT + DESTINATION PHOTO
  // --------------------------------------------------

  Widget _buildUpcomingTrip(
    BuildContext context,
    Trip? trip,
  ) {
    if (trip == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.flight_takeoff_rounded,
              size: 46,
              color: AppColors.primary,
            ),
            SizedBox(height: 12),
            Text(
              'No upcoming trips yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Plan your next adventure to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final duration = trip.endDate.difference(trip.startDate).inDays + 1;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailsScreen(trip: trip),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ORIGINAL HEADER
            const Row(
              children: [
                Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Upcoming Trip',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

           // DESTINATION IMAGE WITH ERROR DIAGNOSTICS
// LARGE RESPONSIVE DESTINATION IMAGE
ClipRRect(
  borderRadius: BorderRadius.circular(18),
  child: AspectRatio(
    aspectRatio: 16 / 9,
    child: Image.asset(
      TripImageHelper.getImage(trip.destination),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('IMAGE ERROR: $error');

        return Container(
          color: Colors.white24,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 54,
              color: Colors.white,
            ),
          ),
        );
      },
    ),
  ),
),

            // ACTUAL DESTINATION FROM FIRESTORE
            Text(
              '${trip.destination}, ${trip.country}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // ACTUAL DATES FROM FIRESTORE
            Text(
              '${_formatDate(trip.startDate)} - '
              '${_formatDate(trip.endDate)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 12),

            // TRIP TYPE
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trip.tripType,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ORIGINAL INFORMATION ROW
            Row(
              children: [
                Expanded(
                  child: _tripInfo(
                    Icons.calendar_month_rounded,
                    '$duration Days',
                  ),
                ),
                Expanded(
                  child: _tripInfo(
                    Icons.payments_outlined,
                    'Rs. ${trip.budget.toStringAsFixed(0)}',
                  ),
                ),
                Expanded(
                  child: _tripInfo(
                    Icons.place_outlined,
                    trip.country,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Trip Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripInfo(
    IconData icon,
    String value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),

        const SizedBox(height: 6),

        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // --------------------------------------------------
  // QUICK ACTIONS — ORIGINAL DESIGN
  // --------------------------------------------------

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickActionCard(
            icon: Icons.add_location_alt_outlined,
            title: 'Plan Trip',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _quickActionCard(
            icon: Icons.route_outlined,
            title: 'Itinerary',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _quickActionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Budget',
          ),
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // TRAVEL OVERVIEW — ORIGINAL DESIGN, REAL COUNTS
  // --------------------------------------------------

  Widget _buildStats({
    required int tripCount,
    required int countryCount,
    required int upcomingCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.flight_rounded,
            value: '$tripCount',
            label: 'Trips',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            icon: Icons.public_rounded,
            value: '$countryCount',
            label: 'Countries',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            icon: Icons.calendar_month_rounded,
            value: '$upcomingCount',
            label: 'Upcoming',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 26,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}