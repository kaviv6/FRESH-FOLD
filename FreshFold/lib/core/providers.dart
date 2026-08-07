import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/api_client.dart';
import 'storage/auth_storage.dart';

/// App-wide singletons. Feature-level providers (repositories, controllers)
/// live next to their feature and read these.
final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(authStorage: ref.watch(authStorageProvider));
});
