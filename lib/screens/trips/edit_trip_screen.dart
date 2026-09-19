import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/trip.dart';

class EditTripScreen extends StatefulWidget {
  final Trip trip;

  const EditTripScreen({
    super.key,
    required this.trip,
  });

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _destinationController;
  late final TextEditingController _countryController;
  late final TextEditingController _budgetController;
  late final TextEditingController _notesController;

  late DateTime _startDate;
  late DateTime _endDate;
  late String _tripType;

  bool _isSaving = false;

  final List<String> _tripTypes = [
    'Leisure',
    'Business',
    'Family',
    'Adventure',
    'Solo',
  ];

  @override
  void initState() {
    super.initState();

    final trip = widget.trip;

    _destinationController =
        TextEditingController(text: trip.destination);

    _countryController =
        TextEditingController(text: trip.country);

    _budgetController =
        TextEditingController(text: trip.budget.toStringAsFixed(0));

    _notesController =
        TextEditingController(text: trip.notes);

    _startDate = trip.startDate;
    _endDate = trip.endDate;

    _tripType = _tripTypes.contains(trip.tripType)
        ? trip.tripType
        : 'Leisure';
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _countryController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final currentDate = isStart ? _startDate : _endDate;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
    );

    if (selectedDate == null) return;

    setState(() {
      if (isStart) {
        _startDate = selectedDate;

        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = selectedDate;
      }
    });
  }

  Future<void> _updateTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before start date.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again.'),
        ),
      );
      return;
    }

    final budget =
        double.tryParse(_budgetController.text.trim());

    if (budget == null || budget <= 0) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final tripRef = FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.trip.id);

      // Read the document first so a missing trip cannot
      // accidentally be recreated by update().
      final tripSnapshot = await tripRef.get();

      if (!tripSnapshot.exists) {
        throw Exception('This trip no longer exists.');
      }

      if (tripSnapshot.data()?['userId'] != user.uid) {
        throw Exception('You do not have access to this trip.');
      }

      await tripRef.update({
        'destination': _destinationController.text.trim(),
        'country': _countryController.text.trim(),
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'budget': budget,
        'tripType': _tripType,
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update trip: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _dateCard(
    String label,
    DateTime date,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: _isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _formatDate(date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Trip',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.edit_location_alt_outlined,
                      color: Colors.white,
                      size: 34,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Update your adventure ✈️',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Make changes to your travel plans.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _sectionTitle('Destination'),

              TextFormField(
                controller: _destinationController,
                enabled: !_isSaving,
                decoration: _inputDecoration(
                  'Enter destination',
                  Icons.location_city_outlined,
                ),
                validator: (value) =>
                    value == null || value.trim().length < 2
                        ? 'Enter a valid destination'
                        : null,
              ),

              const SizedBox(height: 20),

              _sectionTitle('Country'),

              TextFormField(
                controller: _countryController,
                enabled: !_isSaving,
                decoration: _inputDecoration(
                  'Enter country',
                  Icons.public_rounded,
                ),
                validator: (value) =>
                    value == null || value.trim().length < 2
                        ? 'Enter a valid country'
                        : null,
              ),

              const SizedBox(height: 24),

              _sectionTitle('Trip Dates'),

              Row(
                children: [
                  _dateCard(
                    'Start Date',
                    _startDate,
                    () => _pickDate(isStart: true),
                  ),
                  const SizedBox(width: 12),
                  _dateCard(
                    'End Date',
                    _endDate,
                    () => _pickDate(isStart: false),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _sectionTitle('Budget'),

              TextFormField(
                controller: _budgetController,
                enabled: !_isSaving,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  'Enter budget in Rs.',
                  Icons.account_balance_wallet_outlined,
                ),
                validator: (value) {
                  final budget =
                      double.tryParse(value?.trim() ?? '');

                  if (budget == null || budget <= 0) {
                    return 'Enter a valid budget';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              _sectionTitle('Trip Type'),

              DropdownButtonFormField<String>(
                initialValue: _tripType,
                decoration: _inputDecoration(
                  'Choose trip type',
                  Icons.travel_explore_rounded,
                ),
                items: _tripTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _tripType = value);
                        }
                      },
              ),

              const SizedBox(height: 24),

              _sectionTitle('Notes'),

              TextFormField(
                controller: _notesController,
                enabled: !_isSaving,
                maxLines: 4,
                decoration: _inputDecoration(
                  'Add notes about your trip...',
                  Icons.notes_rounded,
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _updateTrip,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'Saving Changes...'
                        : 'Save Changes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}