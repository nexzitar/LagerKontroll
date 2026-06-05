import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../detail/domain/entities/location_data.dart';

/// Use case for getting current GPS location
class GetCurrentLocation {
  /// Get the current device location
  Future<Either<Failure, LocationData>> call() async {
    try {
      logger.debug('Getting current location...');

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        logger.warning('Location services are disabled');
        return const Left(
          LocationFailure('Location services are disabled. Please enable location services.'),
        );
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        logger.debug('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          logger.warning('Location permission denied');
          return const Left(
            PermissionFailure('Location permission denied'),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        logger.warning('Location permission denied forever');
        return const Left(
          PermissionFailure(
            'Location permissions are permanently denied. Please enable them in settings.',
          ),
        );
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      logger.info('Location obtained: ${position.latitude}, ${position.longitude}');

      final locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp ?? DateTime.now(),
      );

      return Right(locationData);
    } catch (e, stackTrace) {
      logger.error('Failed to get location', e, stackTrace);
      return Left(LocationFailure('Failed to get location: ${e.toString()}'));
    }
  }
}
