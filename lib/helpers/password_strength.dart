import 'package:flutter/material.dart';
enum CustomPassStrength {
  weak,
  medium,
  strong,
  secure;

  Color get statusColor {
    switch (this) {
      case CustomPassStrength.weak:
        return Colors.red;
      case CustomPassStrength.medium:
        return Colors.orange;
      case CustomPassStrength.strong:
        return Colors.lightGreenAccent;
      case CustomPassStrength.secure:
        return Colors.green;
    }
  }


  Widget get statusWidget {
    switch (this) {
      case CustomPassStrength.weak:
        return const Text('Weak', style: TextStyle(color: Colors.red));
      case CustomPassStrength.medium:
        return const Text('Medium', style: TextStyle(color: Colors.orange));
      case CustomPassStrength.strong:
        return const Text('Strong', style: TextStyle(color: Colors.lightGreenAccent));
      case CustomPassStrength.secure:
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.check, color: Colors.green),
            const SizedBox(width: 8),
            const Text(
              'Secure',
              style: TextStyle(color: Colors.green),
            ),
          ],
        );
    }
  }

  double get widthPerc {
    switch (this) {
      case CustomPassStrength.weak:
        return 0.15;
      case CustomPassStrength.medium:
        return 0.4;
      case CustomPassStrength.strong:
        return 0.75;
      case CustomPassStrength.secure:
        return 1.0;
    }
  }

  static final RegExp _hasUpper = RegExp(r'[A-Z]');
  static final RegExp _hasLower = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasSpecial = RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]');

  static CustomPassStrength? calculate({required String text}) {
    if (text.isEmpty) return null;

    if (text.length < 6) return CustomPassStrength.weak;

    bool hasUpper = _hasUpper.hasMatch(text);
    bool hasLower = _hasLower.hasMatch(text);
    bool hasDigit = _hasDigit.hasMatch(text);
    bool hasSpecial = _hasSpecial.hasMatch(text);

    if (text.length >= 6 && hasUpper && hasLower && hasDigit && hasSpecial) {
      return CustomPassStrength.secure;
    }

    int complexityCount = [hasUpper, hasLower, hasDigit, hasSpecial]
        .where((element) => element)
        .length;

    if (text.length >= 6 && complexityCount >= 3) {
      return CustomPassStrength.strong;
    }

    return CustomPassStrength.weak;
  }
}