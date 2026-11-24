/// Stock placeholder photos (unrelated to the actual opportunity) are treated
/// as "no banner" so cards fall back to a clean designed banner instead of
/// showing a random image.
bool isPlaceholderPhotoUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return url.toLowerCase().contains('images.unsplash.com');
}

/// Logo images (square thumbnails) should not be zoomed in with BoxFit.cover
/// on detail banners to prevent awkward pixelated or circular clipping.
bool isLogoPhotoUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final lower = url.toLowerCase();
  return lower.contains('150x150') ||
      lower.contains('/logo/') ||
      lower.contains('organisation_image') ||
      lower.contains('organization_image') ||
      lower.endsWith('_logo.jpg') ||
      lower.endsWith('_logo.png');
}
