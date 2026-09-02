import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/trip.dart';

class TripDetailsScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailsScreen({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          trip.destination,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),

            const SizedBox(height: 26),

            const Text(
              'Trip Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _overviewCard(
                    Icons.calendar_month_rounded,
                    'Dates',
                    '${trip.startDate}\n${trip.endDate}',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _overviewCard(
                    Icons.account_balance_wallet_outlined,
                    'Budget',
                    trip.budget,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Itinerary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text('Add Activity'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildActivity(
              time: '09:00 AM',
              title: 'Hotel Check-in',
              icon: Icons.hotel_outlined,
            ),

            _buildActivity(
              time: '11:00 AM',
              title: 'City Exploration',
              icon: Icons.location_on_outlined,
            ),

            _buildActivity(
              time: '06:30 PM',
              title: 'Dinner',
              icon: Icons.restaurant_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          const Icon(
            Icons.flight_takeoff_rounded,
            color: Colors.white,
            size: 36,
          ),

          const SizedBox(height: 24),

          Text(
            '${trip.destination}, ${trip.country}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            trip.status,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivity({
    required String time,
    required String title,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}