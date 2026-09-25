class Validators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email address!';
    return null;
  }

  static String? password(String? value){
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8)return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)|| !RegExp(r'[0-9]').hasMatch(value)){
      return 'Password must contain at least one letter and one number';
    }
    return null;
  }

  static String? required(String? value, {String label = 'This Field'}){
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? httpUrl(
      String? value, {
        bool required = true,
        String label = 'URL',
      }) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) {
      return required ? '$label is required' : null;
    }
    final uri = Uri.tryParse(v);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return '$label must be a valid http:// or https:// link';
    }
    return null;
  }
}