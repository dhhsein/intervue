import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/screening_data.dart';
import 'data_service_provider.dart';
import 'save_status_provider.dart';

/// Provider for screening data of a specific candidate.
final screeningDataProvider = FutureProvider.family<ScreeningData?, String>(
  (ref, candidateId) async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getScreening(candidateId);
  },
);

/// Notifier for managing screening data state and auto-saving.
class ScreeningNotifier extends FamilyAsyncNotifier<ScreeningData, String> {
  late String _candidateId;

  @override
  Future<ScreeningData> build(String arg) async {
    _candidateId = arg;
    final dataService = ref.read(dataServiceProvider);
    final data = await dataService.getScreening(_candidateId);
    return data ?? ScreeningData();
  }

  Future<void> _save(ScreeningData data) async {
    ref.read(saveStatusProvider.notifier).setSaving();
    try {
      final dataService = ref.read(dataServiceProvider);
      await dataService.saveScreening(_candidateId, data);
      ref.read(saveStatusProvider.notifier).setSaved();
    } catch (e) {
      ref.read(saveStatusProvider.notifier).setError();
      rethrow;
    }
  }

  /// Update a single screening response.
  Future<void> updateResponse(
    String questionId,
    ScreeningResponse response,
  ) async {
    final current = state.valueOrNull ?? ScreeningData();
    final newResponses = Map<String, ScreeningResponse>.from(current.responses);
    newResponses[questionId] = response;
    final updated = ScreeningData(
      emailSentAt: current.emailSentAt,
      responseReceivedAt: current.responseReceivedAt,
      phoneScreenAt: current.phoneScreenAt,
      grade: current.grade,
      responses: newResponses,
      phoneScreen: current.phoneScreen,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update the screening grade.
  Future<void> updateGrade(ScreeningGrade? grade) async {
    final current = state.valueOrNull ?? ScreeningData();
    final updated = ScreeningData(
      emailSentAt: current.emailSentAt,
      responseReceivedAt: current.responseReceivedAt,
      phoneScreenAt: current.phoneScreenAt,
      grade: grade,
      responses: current.responses,
      phoneScreen: current.phoneScreen,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update the phone screen data.
  Future<void> updatePhoneScreen(PhoneScreenData phoneScreen) async {
    final current = state.valueOrNull ?? ScreeningData();
    final updated = ScreeningData(
      emailSentAt: current.emailSentAt,
      responseReceivedAt: current.responseReceivedAt,
      phoneScreenAt: phoneScreen.conducted ? (current.phoneScreenAt ?? DateTime.now()) : null,
      grade: current.grade,
      responses: current.responses,
      phoneScreen: phoneScreen,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Mark response as received.
  Future<void> markResponseReceived() async {
    final current = state.valueOrNull ?? ScreeningData();
    final updated = ScreeningData(
      emailSentAt: current.emailSentAt,
      responseReceivedAt: DateTime.now(),
      phoneScreenAt: current.phoneScreenAt,
      grade: current.grade,
      responses: current.responses,
      phoneScreen: current.phoneScreen,
    );
    state = AsyncData(updated);
    await _save(updated);
  }
}

final screeningNotifierProvider =
    AsyncNotifierProvider.family<ScreeningNotifier, ScreeningData, String>(
  ScreeningNotifier.new,
);
