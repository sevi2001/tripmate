import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/trip.dart';
import 'trip_expenses_screen.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Expenses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please log in to view your expenses.',
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .where(
                    'userId',
                    isEqualTo: user.uid,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
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
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No trips yet.\nCreate a trip first to track its expenses.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                final trips = docs.map((doc) {
                  final data = doc.data();

                  return Trip(
                    id: doc.id,
                    userId: data['userId']?.toString() ?? '',
                    destination:
                        data['destination']?.toString() ?? '',
                    country: data['country']?.toString() ?? '',
                    startDate:
                        (data['startDate'] as Timestamp).toDate(),
                    endDate:
                        (data['endDate'] as Timestamp).toDate(),
                    budget:
                        (data['budget'] as num).toDouble(),
                    tripType:
                        data['tripType']?.toString() ?? '',
                    notes: data['notes']?.toString() ?? '',
                    status:
                        data['status']?.toString() ?? 'Upcoming',
                  );
                }).toList();

                trips.sort(
                  (a, b) =>
                      a.startDate.compareTo(b.startDate),
                );

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Select a trip to manage its expenses',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Each trip has its own budget and expenses.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    ...trips.map(
                      (trip) => _tripCard(
                        context,
                        trip,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _tripCard(
    BuildContext context,
    Trip trip,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          '${trip.destination}, ${trip.country}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Budget: Rs. ${trip.budget.toStringAsFixed(0)}',
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TripExpensesScreen(trip: trip),
            ),
          );
        },
      ),
    );
  }
}