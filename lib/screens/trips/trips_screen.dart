import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/utils/trip_image_helper.dart';
import '../../models/trip.dart';
import 'trip_details_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  String _searchQuery = '';

  String _selectedFilter = 'Upcoming';

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
                child: Text(
                  'Failed to load trips:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final trips = snapshot.data?.docs
                    .map((doc) => Trip.fromFirestore(doc))
                    .toList() ??
                <Trip>[];

            final now = DateTime.now();

            final today = DateTime(
              now.year,
              now.month,
              now.day,
            );

            final upcomingTrips = trips.where((trip) {
              return !trip.endDate.isBefore(today);
            }).toList();

            final pastTrips = trips.where((trip) {
              return trip.endDate.isBefore(today);
            }).toList();

            upcomingTrips.sort(
              (a, b) => a.startDate.compareTo(b.startDate),
            );

            pastTrips.sort(
              (a, b) => b.endDate.compareTo(a.endDate),
            );

            final selectedTrips = _selectedFilter == 'Upcoming'
                ? upcomingTrips
                : pastTrips;

            final filteredTrips = selectedTrips.where((trip) {
              final query = _searchQuery.toLowerCase();

              return trip.destination.toLowerCase().contains(query) ||
                  trip.country.toLowerCase().contains(query);
            }).toList();

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      20,
                      16,
                      24,
                    ),
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 22),

                      _buildSearchBar(),

                      const SizedBox(height: 20),

                      _buildFilters(
                        upcomingTrips.length,
                        pastTrips.length,
                      ),

                      const SizedBox(height: 22),

                      if (filteredTrips.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredTrips.map(
                          (trip) => _buildTripCard(
                            context,
                            trip,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // MainNavigationScreen already has a Plan tab.
          // Open that tab to create a trip.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tap the Plan tab below to create a new trip.',
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Trip'),
      ),
    );
  }

  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Trips',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 5),

        Text(
          'Your next adventures await! ✈️',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SEARCH
  // --------------------------------------------------

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search destinations...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // UPCOMING / PAST FILTERS
  // --------------------------------------------------

  Widget _buildFilters(
    int upcomingCount,
    int pastCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: _filterButton(
            title: 'Upcoming',
            count: upcomingCount,
            icon: Icons.flight_takeoff_rounded,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _filterButton(
            title: 'Past',
            count: pastCount,
            icon: Icons.history_rounded,
          ),
        ),
      ],
    );
  }

  Widget _filterButton({
    required String title,
    required int count,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == title;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),

            const SizedBox(width: 6),

            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(width: 6),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TRIP CARD
  // --------------------------------------------------

  Widget _buildTripCard(
    BuildContext context,
    Trip trip,
  ) {
    final categoryColor = _getCategoryColor(trip.tripType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 580;

              if (isCompact) {
                return _buildCompactCard(
                  trip,
                  categoryColor,
                );
              }

              return _buildWideCard(
                trip,
                categoryColor,
              );
            },
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // DESKTOP / TABLET CARD
  // --------------------------------------------------

  Widget _buildWideCard(
    Trip trip,
    Color categoryColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTripImage(
          trip,
          width: 210,
          height: 175,
        ),

        const SizedBox(width: 20),

        Expanded(
          child: _buildTripInformation(
            trip,
            categoryColor,
          ),
        ),

        const SizedBox(width: 12),

        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 17,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // MOBILE CARD
  // --------------------------------------------------

  Widget _buildCompactCard(
    Trip trip,
    Color categoryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTripImage(
          trip,
          width: double.infinity,
          height: 180,
        ),

        const SizedBox(height: 16),

        _buildTripInformation(
          trip,
          categoryColor,
        ),

        const SizedBox(height: 12),

        const Align(
          alignment: Alignment.centerRight,
          child: Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // DESTINATION IMAGE
  // --------------------------------------------------

  Widget _buildTripImage(
    Trip trip, {
    required double width,
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.asset(
            TripImageHelper.getImage(trip.destination),
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: AppColors.primary.withValues(alpha: 0.10),
                child: const Icon(
                  Icons.landscape_outlined,
                  color: AppColors.primary,
                  size: 40,
                ),
              );
            },
          ),

          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 14,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    trip.destination,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // TRIP DETAILS INSIDE CARD
  // --------------------------------------------------

  Widget _buildTripInformation(
    Trip trip,
    Color categoryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${trip.destination}, ${trip.country}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            trip.tripType,
            style: TextStyle(
              color: categoryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _dateInfo(
                'Start Date',
                trip.startDate,
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),

            Expanded(
              child: _dateInfo(
                'End Date',
                trip.endDate,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.green,
              size: 21,
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                'Rs. ${trip.budget.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 3),

        const Padding(
          padding: EdgeInsets.only(left: 29),
          child: Text(
            'Budget',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateInfo(
    String label,
    DateTime date,
  ) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_month_outlined,
          color: AppColors.primary,
          size: 21,
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.flight_takeoff_rounded,
            size: 48,
            color: AppColors.primary,
          ),

          const SizedBox(height: 14),

          Text(
            _searchQuery.isNotEmpty
                ? 'No matching trips found'
                : _selectedFilter == 'Upcoming'
                    ? 'No upcoming trips'
                    : 'No past trips',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your travel adventures will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'family':
        return Colors.blue;

      case 'leisure':
        return Colors.green;

      case 'adventure':
        return Colors.orange;

      case 'honeymoon':
        return Colors.purple;

      case 'business':
        return Colors.indigo;

      default:
        return AppColors.primary;
    }
  }
}