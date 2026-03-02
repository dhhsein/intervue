import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_config.dart';
import 'data_service_provider.dart';

/// Provider for app configuration.
final configProvider = FutureProvider<AppConfig>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return dataService.getConfig();
});
