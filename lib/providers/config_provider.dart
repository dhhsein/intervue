import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_config.dart';
import 'data_service_provider.dart';

/// Provider for app configuration.
final configProvider = AsyncNotifierProvider<ConfigNotifier, AppConfig>(() {
  return ConfigNotifier();
});

class ConfigNotifier extends AsyncNotifier<AppConfig> {
  @override
  Future<AppConfig> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getConfig();
  }

  Future<void> updateConfig({
    String? interviewerName,
    String? companyName,
    String? roleName,
    String? location,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AppConfig(
      interviewerName: interviewerName ?? current.interviewerName,
      companyName: companyName ?? current.companyName,
      roleName: roleName ?? current.roleName,
      location: location ?? current.location,
      emailTemplate: current.emailTemplate,
      rejectionTemplate: current.rejectionTemplate,
      assignmentBrief: current.assignmentBrief,
      serverPort: current.serverPort,
    );

    final dataService = ref.read(dataServiceProvider);
    final saved = await dataService.saveConfig(updated);
    state = AsyncValue.data(saved);
  }
}
