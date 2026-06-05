import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../../features/browse/data/datasources/trailer_list_local_datasource.dart';
import '../../features/browse/data/datasources/trailer_list_remote_datasource.dart';
import '../../features/browse/data/repositories/trailer_list_repository_impl.dart';
import '../../features/browse/domain/repositories/trailer_list_repository.dart';
import '../../features/browse/domain/usecases/get_trailers.dart';
import '../../features/browse/domain/usecases/search_trailers.dart';
import '../../features/capture/data/datasources/trailer_remote_datasource.dart';
import '../../features/capture/data/repositories/trailer_repository_impl.dart';
import '../../features/capture/data/repositories/trailer_repository_mock.dart';
import '../../features/capture/domain/repositories/trailer_repository.dart';
import '../../features/capture/domain/usecases/create_trailer_entry.dart';
import '../../features/capture/domain/usecases/get_address_from_coordinates.dart';
import '../../features/capture/domain/usecases/get_current_location.dart';
import '../../features/detail/data/datasources/trailer_detail_remote_datasource.dart';
import '../../features/detail/data/repositories/trailer_detail_repository_impl.dart';
import '../../features/detail/domain/repositories/trailer_detail_repository.dart';
import '../../features/detail/domain/usecases/get_trailer_detail.dart';
import '../../features/detail/domain/usecases/get_trailer_history.dart';
import '../../features/detail/domain/usecases/update_trailer_status.dart';

// Core Providers
final dioClientProvider = Provider<DioClient>((ref) => dioClient);
final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfoImpl(Connectivity()));

// Data Source Providers
final trailerRemoteDataSourceProvider = Provider<TrailerRemoteDataSource>(
  (ref) => TrailerRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

final trailerListRemoteDataSourceProvider = Provider<TrailerListRemoteDataSource>(
  (ref) => TrailerListRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

final trailerListLocalDataSourceProvider = Provider<TrailerListLocalDataSource>(
  (ref) => TrailerListLocalDataSourceImpl(),
);

final trailerDetailRemoteDataSourceProvider = Provider<TrailerDetailRemoteDataSource>(
  (ref) => TrailerDetailRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

// Repository Providers
// ✅ Connected to real backend at lassi.cloud:3000
final trailerRepositoryProvider = Provider<TrailerRepository>((ref) {
  // Real mode - backend connected!
  return TrailerRepositoryImpl(
    remoteDataSource: ref.watch(trailerRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );

  // Mock mode - uncomment to use without backend:
  // return TrailerRepositoryMock();
});

final trailerListRepositoryProvider = Provider<TrailerListRepository>((ref) {
  return TrailerListRepositoryImpl(
    remoteDataSource: ref.watch(trailerListRemoteDataSourceProvider),
    localDataSource: ref.watch(trailerListLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// Repository Providers - Detail
final trailerDetailRepositoryProvider = Provider<TrailerDetailRepository>((ref) {
  return TrailerDetailRepositoryImpl(
    remoteDataSource: ref.watch(trailerDetailRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// Use Case Providers
final createTrailerEntryProvider = Provider<CreateTrailerEntry>(
  (ref) => CreateTrailerEntry(ref.watch(trailerRepositoryProvider)),
);

final getCurrentLocationProvider = Provider<GetCurrentLocation>((ref) => GetCurrentLocation());
final getAddressFromCoordinatesProvider = Provider<GetAddressFromCoordinates>((ref) => GetAddressFromCoordinates());
final getTrailersProvider = Provider<GetTrailers>((ref) => GetTrailers(ref.watch(trailerListRepositoryProvider)));
final searchTrailersProvider = Provider<SearchTrailers>((ref) => SearchTrailers(ref.watch(trailerListRepositoryProvider)));

// Use Case Providers - Detail
final getTrailerDetailProvider = Provider<GetTrailerDetail>(
  (ref) => GetTrailerDetail(ref.watch(trailerDetailRepositoryProvider)),
);

final getTrailerHistoryProvider = Provider<GetTrailerHistory>(
  (ref) => GetTrailerHistory(ref.watch(trailerDetailRepositoryProvider)),
);

final updateTrailerStatusProvider = Provider<UpdateTrailerStatus>(
  (ref) => UpdateTrailerStatus(ref.watch(trailerDetailRepositoryProvider)),
);
