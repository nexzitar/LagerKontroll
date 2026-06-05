import 'package:equatable/equatable.dart';

/// Domain entity representing location data
class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, timestamp];

  @override
  String toString() => 'LocationData(lat: $latitude, lng: $longitude, address: $address)';
}
