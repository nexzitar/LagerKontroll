import 'package:equatable/equatable.dart';

/// Represents location data with coordinates and optional address
class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? address;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.address,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy, address, timestamp];

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, accuracy: $accuracy, address: $address)';
  }

  /// Create a copy with optional new values
  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
    DateTime? timestamp,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
