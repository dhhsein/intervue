import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/candidate.dart';
import 'data_service_provider.dart';

final candidatesProvider =
    AsyncNotifierProvider<CandidatesNotifier, List<Candidate>>(
  CandidatesNotifier.new,
);

class CandidatesNotifier extends AsyncNotifier<List<Candidate>> {
  @override
  Future<List<Candidate>> build() async {
    return _fetchCandidates();
  }

  Future<List<Candidate>> _fetchCandidates() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getCandidates();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchCandidates);
  }

  Future<Candidate> createCandidate({
    required String name,
    required String email,
    String? phone,
  }) async {
    final dataService = ref.read(dataServiceProvider);
    final candidate = await dataService.createCandidate(
      name: name,
      email: email,
      phone: phone,
    );
    await refresh();
    return candidate;
  }

  Future<void> updateCandidate(String id, Map<String, dynamic> updates) async {
    final dataService = ref.read(dataServiceProvider);
    await dataService.updateCandidate(id, updates);
    await refresh();
  }

  Future<void> deleteCandidate(String id) async {
    final dataService = ref.read(dataServiceProvider);
    await dataService.deleteCandidate(id);
    await refresh();
  }
}

final candidateDetailProvider =
    FutureProvider.family<CandidateDetail, String>((ref, id) async {
  final dataService = ref.read(dataServiceProvider);
  return dataService.getCandidate(id);
});

final filteredCandidatesProvider =
    Provider.family<AsyncValue<List<Candidate>>, String>((ref, searchQuery) {
  final candidatesAsync = ref.watch(candidatesProvider);
  return candidatesAsync.whenData((candidates) {
    if (searchQuery.isEmpty) return candidates;
    final query = searchQuery.toLowerCase();
    return candidates.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query);
    }).toList();
  });
});

final candidatesByStageProvider =
    Provider.family<AsyncValue<List<Candidate>>, PipelineStage>(
        (ref, stage) {
  final candidatesAsync = ref.watch(candidatesProvider);
  return candidatesAsync.whenData((candidates) {
    return candidates.where((c) => c.status.pipelineStage == stage).toList();
  });
});
