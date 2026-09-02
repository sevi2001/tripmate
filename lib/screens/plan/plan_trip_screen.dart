import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PlanTripScreen extends StatefulWidget {
  const PlanTripScreen({super.key});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final _destinationController = TextEditingController();
  final _countryController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  String _tripType = 'Leisure';

  final List<String> _tripTypes = [
    'Leisure',
    'Business',
    'Family',
    'Adventure',
    'Solo',
  ];

  @override
  void dispose() {
    _destinationController.dispose();
    _countryController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _startDate = selectedDate;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: _startDate ?? DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _endDate = selectedDate;
      });
    }
  }

  void _saveTrip() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select trip dates'),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip saved successfully'),
      ),
    );

    Navigator.pop(context);
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Plan New Trip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Where are you going?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              const Text('Destination'),
              const SizedBox(height: 8),

              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  hintText: 'Example: Tokyo',
                  prefixIcon: Icon(
                    Icons.location_city_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter destination';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              const Text('Country'),
              const SizedBox(height: 8),

              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  hintText: 'Example: Japan',
                  prefixIcon: Icon(
                    Icons.public_rounded,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter country';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 22),

              const Text(
                'Trip Dates',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _dateCard(
                      title: 'Start Date',
                      date: _formatDate(_startDate),
                      onTap: _selectStartDate,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _dateCard(
                      title: 'End Date',
                      date: _formatDate(_endDate),
                      onTap: _selectEndDate,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const Text('Budget'),
              const SizedBox(height: 8),

              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Example: 120000',
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                  ),
                  prefixText: 'Rs. ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter budget';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 22),

              const Text(
                'Trip Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

             DropdownButtonFormField<String>(
  initialValue: _tripType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.travel_explore_rounded,
                  ),
                ),
                items: _tripTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _tripType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 22),

              const Text('Notes'),
              const SizedBox(height: 8),

              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Add notes about your trip...',
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveTrip,
                  icon: const Icon(
                    Icons.save_outlined,
                  ),
                  label: const Text(
                    'Save Trip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateCard({
    required String title,
    required String date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}