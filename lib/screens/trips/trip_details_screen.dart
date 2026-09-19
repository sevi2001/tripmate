import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/activity.dart';
import '../../models/trip.dart';

import 'add_activity_screen.dart';
import 'edit_trip_screen.dart';
import '../expenses/trip_expenses_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailsScreen({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailsScreen> createState() =>
      _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late Trip trip;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    trip = widget.trip;
  }

  // ==================================================
  // DATE FORMAT
  // ==================================================

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ==================================================
  // FIRESTORE ACTIVITY STREAM
  // ==================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _activityStream() {
    return FirebaseFirestore.instance
        .collection('trips')
        .doc(trip.id)
        .collection('activities')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ==================================================
  // EDIT TRIP
  // ==================================================

  Future<void> _editTrip() async {
    if (_isDeleting) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripScreen(
          trip: trip,
        ),
      ),
    );

    if (updated != true || !mounted) return;

    try {
      final document = await FirebaseFirestore.instance
          .collection('trips')
          .doc(trip.id)
          .get();

      if (!mounted) return;

      if (!document.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This trip no longer exists.'),
          ),
        );

        Navigator.pop(context);
        return;
      }

      setState(() {
        trip = Trip.fromFirestore(document);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to refresh trip: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================================================
  // DELETE TRIP
  // ==================================================

  Future<void> _deleteTrip() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delete Trip?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          content: Text(
            'Are you sure you want to delete your trip to '
            '${trip.destination}?\n\n'
            'All activities and expenses associated with '
            'this trip will also be deleted.\n\n'
            'This action cannot be undone.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
              label: const Text('Delete Trip'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Please log in again.');
      }

      final firestore = FirebaseFirestore.instance;

      final tripReference = firestore
          .collection('trips')
          .doc(trip.id);

      // Check ownership before attempting deletion.
      // Firestore Security Rules must also enforce this.
      final tripDocument = await tripReference.get();

      if (!tripDocument.exists) {
        throw Exception('This trip no longer exists.');
      }

      if (tripDocument.data()?['userId'] != user.uid) {
        throw Exception(
          'You do not have permission to delete this trip.',
        );
      }

      // Delete activities and expenses first.
      // Firestore does not automatically delete subcollections
      // when the parent document is deleted.
      for (final collectionName in [
        'activities',
        'expenses',
      ]) {
        while (true) {
          final snapshot = await tripReference
              .collection(collectionName)
              .limit(100)
              .get();

          if (snapshot.docs.isEmpty) {
            break;
          }

          final batch = firestore.batch();

          for (final document in snapshot.docs) {
            batch.delete(document.reference);
          }

          await batch.commit();
        }
      }

      // Delete the parent trip last.
      await tripReference.delete();

      if (!mounted) return;

      // Return to My Trips / previous screen.
      Navigator.pop(context);

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete trip: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ==================================================
  // MAIN SCREEN
  // ==================================================

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
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ------------------------------------------
            // TRIP HEADER
            // ------------------------------------------

            _buildHeaderCard(),

            const SizedBox(height: 18),

            // ------------------------------------------
            // EDIT / DELETE BUTTONS
            // ------------------------------------------

            _buildTripActionButtons(),

            const SizedBox(height: 30),

            // ------------------------------------------
            // TRIP OVERVIEW
            // ------------------------------------------

            const Text(
              'Trip Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _overviewCard(
                    Icons.calendar_month_rounded,
                    'Dates',
                    '${_formatDate(trip.startDate)}\n'
                    '${_formatDate(trip.endDate)}',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _overviewCard(
                    Icons.account_balance_wallet_outlined,
                    'Budget',
                    'Rs. ${trip.budget.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // ------------------------------------------
            // VIEW EXPENSES
            // ------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton.icon(
                onPressed: _isDeleting
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TripExpensesScreen(
                              trip: trip,
                            ),
                          ),
                        );
                      },

                icon: const Icon(
                  Icons.account_balance_wallet_outlined,
                ),

                label: const Text(
                  'View Trip Expenses',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ------------------------------------------
            // ITINERARY HEADER
            // ------------------------------------------

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Itinerary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                TextButton.icon(
                  onPressed: _isDeleting
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddActivityScreen(
                                tripId: trip.id,
                              ),
                            ),
                          );
                        },

                  icon: const Icon(Icons.add),

                  label: const Text(
                    'Add Activity',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ------------------------------------------
            // FIRESTORE ACTIVITIES
            // ------------------------------------------

            StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _activityStream(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Failed to load activities.\n'
                    '${snapshot.error}',
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: const Column(
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 44,
                          color: AppColors.primary,
                        ),

                        SizedBox(height: 10),

                        Text(
                          'No activities added yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final activities = docs.map((doc) {
                  final data = doc.data();

                  return Activity(
                    id: doc.id,
                    title: data['title']?.toString() ?? '',
                    location:
                        data['location']?.toString() ?? '',
                    time: data['time']?.toString() ?? '',
                    category:
                        data['category']?.toString() ?? '',
                    notes: data['notes']?.toString() ?? '',
                  );
                }).toList();

                return Column(
                  children: activities.map((activity) {
                    return _buildActivity(activity);
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // HEADER CARD
  // ==================================================

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
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // EDIT / DELETE BUTTONS UI
  // ==================================================

  Widget _buildTripActionButtons() {
    return Row(
      children: [
        // EDIT TRIP

        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isDeleting ? null : _editTrip,

            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
            ),

            label: const Text(
              'Edit Trip',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,

              side: const BorderSide(
                color: AppColors.primary,
              ),

              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // DELETE TRIP

        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isDeleting ? null : _deleteTrip,

            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                  ),

            label: Text(
              _isDeleting
                  ? 'Deleting...'
                  : 'Delete Trip',

              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,

              side: const BorderSide(
                color: Colors.red,
              ),

              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================================================
  // OVERVIEW CARD
  // ==================================================

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

  // ==================================================
  // ACTIVITY CARD
  // ==================================================

  Widget _buildActivity(Activity activity) {
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
              color: AppColors.primary.withValues(
                alpha: 0.10,
              ),

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  activity.time,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  activity.location,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                if (activity.category.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    activity.category,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}