// lib/result_analysis/view_model/result_view_model.dart
import 'package:flutter/material.dart';
import '../../data/model/result_profile_data_model.dart';

class ResultViewModel extends ChangeNotifier {
  double? bmi;
  double? bmr;

  void initialize(ResultProfileDataModel profile) {
    final height = profile.height ?? 0.0;
    final weight = profile.weight ?? 0.0;
    final age = profile.age ?? 0;
    final gender = profile.gender ?? '';

    _updateBmi(weight, height);
    _updateBmr(weight, height, age, gender);
  }

  void _updateBmi(double weight, double height) {
    if (weight > 0 && height > 0) {
      final heightInMeters = height / 100;
      bmi = double.parse(
        (weight / (heightInMeters * heightInMeters)).toStringAsFixed(2),
      );
    }
  }

  void _updateBmr(double weight, double height, int age, String gender) {
    if (weight > 0 && height > 0 && age > 0) {
      double result;
      if (gender.toLowerCase() == 'male') {
        result = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else {
        result = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }
      bmr = double.tryParse(result.toStringAsFixed(2));
    }
  }
}
