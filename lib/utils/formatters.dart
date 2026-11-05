/// Formats an amount as grouped Ethiopian Birr, e.g. `12000` -> `12,000`.
String formatEtb(num value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }

  return buffer.toString();
}

/// Accepts `09xxxxxxxx` or `+2519xxxxxxxx` style Ethiopian mobile numbers.
String? validateEthiopianPhone(String? rawValue) {
  final value = (rawValue ?? '').replaceAll(RegExp(r'[\s-]'), '').trim();

  if (value.isEmpty) {
    return 'Enter a phone number';
  }

  if (!RegExp(r'^(\+251|0)(9|7)\d{8}$').hasMatch(value)) {
    return 'Use 09xxxxxxxx, 07xxxxxxxx or +2519xxxxxxxx';
  }

  return null;
}

/// Human-friendly relative date used on listing cards.
String timeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes} min ago';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours} hr ago';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }
  if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '$weeks week${weeks == 1 ? '' : 's'} ago';
  }

  final months = (difference.inDays / 30).floor();
  return '$months month${months == 1 ? '' : 's'} ago';
}
