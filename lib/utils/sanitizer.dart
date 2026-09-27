// SECURITY: Input sanitization utility to strip dangerous control/bidi characters
// and enforce length bounds without corrupting developer code snippets (<T>, &&, etc.).
class Sanitizer {
  static final RegExp _controlAndBidiChars = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F\u202A-\u202E\u2066-\u2069]',
  );

  static String sanitize(String input, {int maxLength = 5000}) {
    if (input.isEmpty) return '';

    // Strip PostgreSQL-unsafe null bytes, non-printable control chars (keep \t, \n, \r),
    // and Unicode bidirectional text-spoofing overrides.
    String sanitized = input.replaceAll(_controlAndBidiChars, '').trim();

    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized;
  }

  static String sanitizeHandle(String handle) {
    final cleaned = handle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return cleaned.length > 32 ? cleaned.substring(0, 32) : cleaned;
  }
}

