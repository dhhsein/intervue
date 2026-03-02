import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interview_question.dart';
import '../models/technical_round.dart';

class InterviewSession {
  final String candidateId;
  final List<InterviewQuestion> selectedQuestions;
  final List<QuestionScore> scores;
  final DateTime startTime;
  int currentQuestionIndex;

  InterviewSession({
    required this.candidateId,
    required this.selectedQuestions,
    List<QuestionScore>? scores,
    DateTime? startTime,
    this.currentQuestionIndex = 0,
  })  : scores = scores ??
            selectedQuestions
                .map((q) => QuestionScore(questionId: q.id))
                .toList(),
        startTime = startTime ?? DateTime.now();

  InterviewQuestion get currentQuestion =>
      selectedQuestions[currentQuestionIndex];

  QuestionScore get currentScore => scores[currentQuestionIndex];

  bool get isFirstQuestion => currentQuestionIndex == 0;

  bool get isLastQuestion =>
      currentQuestionIndex == selectedQuestions.length - 1;

  Duration get elapsed => DateTime.now().difference(startTime);

  InterviewSession copyWith({
    String? candidateId,
    List<InterviewQuestion>? selectedQuestions,
    List<QuestionScore>? scores,
    DateTime? startTime,
    int? currentQuestionIndex,
  }) {
    return InterviewSession(
      candidateId: candidateId ?? this.candidateId,
      selectedQuestions: selectedQuestions ?? this.selectedQuestions,
      scores: scores ?? this.scores,
      startTime: startTime ?? this.startTime,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    );
  }
}

class InterviewNotifier extends Notifier<InterviewSession?> {
  @override
  InterviewSession? build() => null;

  void startInterview(
    String candidateId,
    List<InterviewQuestion> questions,
  ) {
    state = InterviewSession(
      candidateId: candidateId,
      selectedQuestions: questions,
    );
  }

  void updateCurrentScore({
    int? score,
    FraudFlag? fraudFlag,
    String? responseQuality,
    String? responseSummary,
    String? notes,
    bool? skipped,
  }) {
    if (state == null) return;

    final newScores = List<QuestionScore>.from(state!.scores);
    final current = newScores[state!.currentQuestionIndex];

    newScores[state!.currentQuestionIndex] = QuestionScore(
      questionId: current.questionId,
      score: score ?? current.score,
      fraudFlag: fraudFlag ?? current.fraudFlag,
      responseQuality: responseQuality ?? current.responseQuality,
      responseSummary: responseSummary ?? current.responseSummary,
      notes: notes ?? current.notes,
      skipped: skipped ?? current.skipped,
    );

    state = state!.copyWith(scores: newScores);
  }

  void nextQuestion() {
    if (state == null || state!.isLastQuestion) return;
    state = state!.copyWith(
      currentQuestionIndex: state!.currentQuestionIndex + 1,
    );
  }

  void previousQuestion() {
    if (state == null || state!.isFirstQuestion) return;
    state = state!.copyWith(
      currentQuestionIndex: state!.currentQuestionIndex - 1,
    );
  }

  void goToQuestion(int index) {
    if (state == null ||
        index < 0 ||
        index >= state!.selectedQuestions.length) {
      return;
    }
    state = state!.copyWith(currentQuestionIndex: index);
  }

  void skipCurrentQuestion() {
    updateCurrentScore(skipped: true);
    nextQuestion();
  }

  TechnicalRound toTechnicalRound() {
    if (state == null) {
      throw StateError('No active interview session');
    }

    return TechnicalRound(
      candidateId: state!.candidateId,
      date: state!.startTime,
      durationSeconds: state!.elapsed.inSeconds,
      questions: state!.scores,
      completed: true,
    );
  }

  void endInterview() {
    state = null;
  }
}

final interviewProvider =
    NotifierProvider<InterviewNotifier, InterviewSession?>(
  InterviewNotifier.new,
);

final selectedQuestionsProvider =
    StateProvider<Set<String>>((ref) => {});
