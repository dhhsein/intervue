import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interview_question.dart';
import 'data_service_provider.dart';

final screeningQuestionsProvider =
    FutureProvider<List<InterviewQuestion>>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return dataService.getQuestions('screening');
});

final technicalQuestionsProvider =
    FutureProvider<List<InterviewQuestion>>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return dataService.getQuestions('technical');
});

final generalQuestionsProvider =
    FutureProvider<List<InterviewQuestion>>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return dataService.getQuestions('general');
});

final allInterviewQuestionsProvider =
    FutureProvider<List<InterviewQuestion>>((ref) async {
  final technical = await ref.watch(technicalQuestionsProvider.future);
  final general = await ref.watch(generalQuestionsProvider.future);
  return [...technical, ...general];
});

final questionsByCategoryProvider =
    Provider<AsyncValue<Map<String, List<InterviewQuestion>>>>((ref) {
  final questionsAsync = ref.watch(allInterviewQuestionsProvider);
  return questionsAsync.whenData((questions) {
    final grouped = <String, List<InterviewQuestion>>{};
    for (final q in questions) {
      grouped.putIfAbsent(q.category, () => []).add(q);
    }
    return grouped;
  });
});
