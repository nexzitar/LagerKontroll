/// Service for determining which terminal a GPS coordinate falls within.
class TerminalGeofenceService {
  /// Terminal polygon definitions.
  /// Each terminal is defined by a list of (latitude, longitude) points
  /// forming a closed polygon (clockwise or counter-clockwise).
  static const Map<String, List<List<double>>> _terminals = {
    'B1': [
      [59.937669, 10.856688],
      [59.936692, 10.857538],
      [59.935867, 10.853545],
      [59.936204, 10.852728],
      [59.936181, 10.851950],
      [59.936684, 10.851357],
    ],
    'B2': [
      [59.935578, 10.853861],
      [59.934841, 10.853003],
      [59.934211, 10.851695],
      [59.935163, 10.850021],
      [59.936159, 10.852383],
    ],
    'B3': [
      [59.934964, 10.849814],
      [59.933745, 10.851994],
      [59.932002, 10.848152],
      [59.933459, 10.845600],
    ],
    'B4': [
      [59.932830, 10.845978],
      [59.931913, 10.846712],
      [59.930777, 10.845470],
      [59.930988, 10.844730],
      [59.932406, 10.844328],
    ],
    'B5': [
      [59.932419, 10.843942],
      [59.931117, 10.844398],
      [59.930559, 10.842935],
      [59.932262, 10.842582],
    ],
    'ØT': [
      [59.941161, 10.945875],
      [59.938609, 10.948055],
      [59.935746, 10.945021],
      [59.935752, 10.943939],
      [59.939928, 10.941069],
    ],
  };

  /// Determines which terminal the given coordinates are in.
  /// Returns the terminal name (e.g., "B1", "B2", "ØT") or null if not in any terminal.
  static String? getTerminal(double latitude, double longitude) {
    for (final entry in _terminals.entries) {
      if (_isPointInPolygon(latitude, longitude, entry.value)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Point-in-polygon test using ray casting algorithm.
  /// Returns true if the point (lat, lon) is inside the polygon.
  static bool _isPointInPolygon(
    double lat,
    double lon,
    List<List<double>> polygon,
  ) {
    int intersections = 0;
    final n = polygon.length;

    for (int i = 0; i < n; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % n];

      final lat1 = p1[0];
      final lon1 = p1[1];
      final lat2 = p2[0];
      final lon2 = p2[1];

      // Check if the ray from (lat, lon) going east intersects this edge
      if (lat > (lat1 < lat2 ? lat1 : lat2) &&
          lat <= (lat1 > lat2 ? lat1 : lat2)) {
        // Calculate the longitude of intersection
        final lonIntersect =
            lon1 + (lat - lat1) / (lat2 - lat1) * (lon2 - lon1);

        if (lon < lonIntersect) {
          intersections++;
        }
      }
    }

    // Odd number of intersections means point is inside
    return intersections % 2 == 1;
  }

  /// Returns all defined terminal names.
  static List<String> get terminalNames => _terminals.keys.toList();

  /// Returns the bounding box for a terminal.
  /// Returns null if terminal not found.
  /// Format: (southWestLat, southWestLon, northEastLat, northEastLon)
  static ({double swLat, double swLon, double neLat, double neLon})? getTerminalBounds(String terminal) {
    final polygon = _terminals[terminal];
    if (polygon == null || polygon.isEmpty) return null;

    double minLat = polygon[0][0];
    double maxLat = polygon[0][0];
    double minLon = polygon[0][1];
    double maxLon = polygon[0][1];

    for (final point in polygon) {
      if (point[0] < minLat) minLat = point[0];
      if (point[0] > maxLat) maxLat = point[0];
      if (point[1] < minLon) minLon = point[1];
      if (point[1] > maxLon) maxLon = point[1];
    }

    return (swLat: minLat, swLon: minLon, neLat: maxLat, neLon: maxLon);
  }
}
