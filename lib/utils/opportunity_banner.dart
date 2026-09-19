/// Stock placeholder photos (unrelated to the actual opportunity) are treated
/// as "no banner" so cards fall back to a clean designed banner instead of
/// showing a random image.
bool isPlaceholderPhotoUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return url.toLowerCase().contains('images.unsplash.com');
}
