/// Google Maps configuration for the university detail page.
class MapsConfig {
  const MapsConfig._();

  /// TODO: add your Google Maps Static API key here (or load it from a
  /// secure source / Firebase Remote Config). Until then the map section
  /// renders a graceful placeholder with the coordinates.
  static const String apiKey = '';

  /// Builds a Google Maps Static API image URL for the given coordinates.
  /// Returns null when no API key is configured (or coordinates are missing)
  /// so the UI can show a placeholder instead of a broken image.
  static String? staticMapUrl({
    required double lat,
    required double lng,
    int width = 640,
    int height = 320,
    int zoom = 12,
  }) {
    if (apiKey.isEmpty) return null;
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&scale=2'
        '&markers=color:0xFFC700%7C$lat,$lng'
        '&key=$apiKey';
  }
}
