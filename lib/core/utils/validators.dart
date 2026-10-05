abstract final class Validators {
  static String? email(String? v) =>
      (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Enter a valid email' : null;
  static String? password(String? v) =>
      (v == null || v.length < 8) ? 'At least 8 characters' : null;
  static String? required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
}