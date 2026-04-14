// SECURITY: Input sanitization utility to prevent XSS and injection attacks.
class Sanitizer {
  static String sanitize(String input) {
    if (input.isEmpty) return '';
    
    // Strip HTML tags
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
    
    // Trim extra whitespace
    sanitized = sanitized.trim();
    
    return sanitized;
  }

  static String sanitizeHandle(String handle) {
    return handle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }
}
