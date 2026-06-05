import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../browse/domain/entities/trailer.dart';
import '../../../capture/domain/entities/trailer_entry.dart';
import '../entities/history_response.dart';

/// Repository interface for trailer detail operations
abstract class TrailerDetailRepository {
  /// Get detailed information about a specific trailer
  Future<Either<Failure, Trailer>> getTrailerById(String id);

  /// Get history of entries for a specific trailer with pagination
  Future<Either<Failure, HistoryResponse>> getTrailerHistory(
    String trailerId,
    int limit,
    int offset,
  );

  /// Update trailer status (mark as empty or change location)
  Future<Either<Failure, TrailerEntry>> updateTrailerStatus({
    required String trailerId,
    required String trailerNumber,
    required String terminal,
    required bool isEmpty,
    required double latitude,
    required double longitude,
    bool isInRamp = false,
    String? rampNumber,
    String? address,
    String? notes,
  });
}
