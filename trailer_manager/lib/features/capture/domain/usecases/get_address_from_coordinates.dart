import 'package:dartz/dartz.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';

/// Use case for reverse geocoding (getting address from coordinates)
class GetAddressFromCoordinates {
  /// Get address from latitude and longitude
  Future<Either<Failure, String>> call({
    required double latitude,
    required double longitude,
  }) async {
    try {
      logger.debug('Getting address for coordinates: $latitude, $longitude');

      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        logger.warning('No address found for coordinates');
        return const Right('Unknown location');
      }

      final placemark = placemarks.first;
      final address = _formatAddress(placemark);

      logger.info('Address found: $address');
      return Right(address);
    } catch (e, stackTrace) {
      logger.error('Failed to get address', e, stackTrace);
      return Left(LocationFailure('Failed to get address: ${e.toString()}'));
    }
  }

  /// Format placemark into a readable address
  String _formatAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }
}
