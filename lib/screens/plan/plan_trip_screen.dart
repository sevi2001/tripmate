import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PlanTripScreen extends StatefulWidget {
  const PlanTripScreen({super.key});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _destinationController =
      TextEditingController();
  final TextEditingController _countryController =
      TextEditingController();
  final TextEditingController _budgetController =
      TextEditingController();
  final TextEditingController _notesController =
      TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  String _tripType = 'Leisure';

  bool _isLoading = false;

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
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: DateTime(2035),
      initialDate: _startDate ?? now,
    );

    if (selectedDate != null) {
      setState(() {
        _startDate = selectedDate;

        if (_endDate != null &&
            _endDate!.isBefore(selectedDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final now = DateTime.now();

    final firstAllowedDate = _startDate ??
        DateTime(
          now.year,
          now.month,
          now.day,
        );

    final selectedDate = await showDatePicker(
      context: context,
      firstDate: firstAllowedDate,
      lastDate: DateTime(2035),
      initialDate: _endDate ?? firstAllowedDate,
    );

    if (selectedDate != null) {
      setState(() {
        _endDate = selectedDate;
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a start date.',
          ),
        ),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an end date.',
          ),
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'End date cannot be before start date.',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be logged in to save a trip.',
          ),
        ),
      );
      return;
    }

    final budget = double.tryParse(
      _budgetController.text.trim(),
    );

    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid budget.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .add({
        'userId': user.uid,
        'destination':
            _destinationController.text.trim(),
        'country':
            _countryController.text.trim(),
        'startDate':
            Timestamp.fromDate(_startDate!),
        'endDate':
            Timestamp.fromDate(_endDate!),
        'budget': budget,
        'tripType': _tripType,
        'notes':
            _notesController.text.trim(),
        'status': 'Upcoming',
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trip saved successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Failed to save trip.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      backgroundColor:
          AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Plan New Trip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Where are you going?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              const Text(
                'Destination',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                    _destinationController,
                enabled: !_isLoading,
                textCapitalization:
                    TextCapitalization.words,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Example: Tokyo',
                  prefixIcon: Icon(
                    Icons
                        .location_city_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value
                          .trim()
                          .isEmpty) {
                    return 'Please enter destination';
                  }

                  if (value.trim().length <
                      2) {
                    return 'Please enter a valid destination';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'Country',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                    _countryController,
                enabled: !_isLoading,
                textCapitalization:
                    TextCapitalization.words,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Example: Japan',
                  prefixIcon: Icon(
                    Icons.public_rounded,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value
                          .trim()
                          .isEmpty) {
                    return 'Please enter country';
                  }

                  if (value.trim().length <
                      2) {
                    return 'Please enter a valid country';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 22,
              ),

              const Text(
                'Trip Dates',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  Expanded(
                    child: _dateCard(
                      title:
                          'Start Date',
                      date: _formatDate(
                        _startDate,
                      ),
                      onTap:
                          _isLoading
                              ? () {}
                              : _selectStartDate,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: _dateCard(
                      title:
                          'End Date',
                      date: _formatDate(
                        _endDate,
                      ),
                      onTap:
                          _isLoading
                              ? () {}
                              : _selectEndDate,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 22,
              ),

              const Text(
                'Budget',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextFormField(
                controller:
                    _budgetController,
                enabled: !_isLoading,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  hintText:
                      'Example: 120000',
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                  ),
                  prefixText: 'Rs. ',
                ),
                validator: (value) {
                  if (value == null ||
                      value
                          .trim()
                          .isEmpty) {
                    return 'Please enter budget';
                  }

                  final budget =
                      double.tryParse(
                    value.trim(),
                  );

                  if (budget == null ||
                      budget <= 0) {
                    return 'Please enter a valid budget';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 22,
              ),

              const Text(
                'Trip Type',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              DropdownButtonFormField<
                  String>(
                initialValue:
                    _tripType,
                decoration:
                    const InputDecoration(
                  prefixIcon: Icon(
                    Icons
                        .travel_explore_rounded,
                  ),
                ),
                items:
                    _tripTypes.map(
                  (type) {
                    return DropdownMenuItem<
                        String>(
                      value: type,
                      child:
                          Text(type),
                    );
                  },
                ).toList(),
                onChanged:
                    _isLoading
                        ? null
                        : (value) {
                            if (value !=
                                null) {
                              setState(
                                () {
                                  _tripType =
                                      value;
                                },
                              );
                            }
                          },
              ),

              const SizedBox(
                height: 22,
              ),

              const Text(
                'Notes',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextFormField(
                controller:
                    _notesController,
                enabled: !_isLoading,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Add notes about your trip...',
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              SizedBox(
                width: double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _isLoading
                          ? null
                          : _saveTrip,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .save_outlined,
                        ),
                  label: Text(
                    _isLoading
                        ? 'Saving...'
                        : 'Save Trip',
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
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
      borderRadius:
          BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(
                color:
                    AppColors
                        .textSecondary,
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                const Icon(
                  Icons
                      .calendar_month_outlined,
                  color:
                      AppColors.primary,
                  size: 20,
                ),

                const SizedBox(
                  width: 6,
                ),

                Expanded(
                  child: Text(
                    date,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .w600,
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