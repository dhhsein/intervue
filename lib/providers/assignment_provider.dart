import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/assignment_review.dart';
import '../models/technical_round.dart';
import 'data_service_provider.dart';
import 'save_status_provider.dart';

/// Default scoring areas with their weights.
const defaultScoringAreas = [
  {'id': 'code_quality', 'name': 'Code Quality', 'weight': 25},
  {'id': 'correctness', 'name': 'Correctness', 'weight': 25},
  {'id': 'testing', 'name': 'Testing', 'weight': 20},
  {'id': 'api_design', 'name': 'API Design', 'weight': 15},
  {'id': 'devops', 'name': 'DevOps', 'weight': 15},
];

/// Notifier for managing assignment review data state and auto-saving.
class AssignmentReviewNotifier
    extends FamilyAsyncNotifier<AssignmentReview, String> {
  late String _candidateId;

  @override
  Future<AssignmentReview> build(String arg) async {
    _candidateId = arg;
    final dataService = ref.read(dataServiceProvider);
    final data = await dataService.getAssignmentReview(_candidateId);

    if (data != null) {
      return data;
    }

    // Initialize with default scoring areas
    final defaultScores = <String, AreaScore>{};
    for (final area in defaultScoringAreas) {
      final id = area['id'] as String;
      defaultScores[id] = AreaScore(
        areaId: id,
        displayName: area['name'] as String,
        weight: area['weight'] as int,
      );
    }

    return AssignmentReview(
      candidateId: _candidateId,
      areaScores: defaultScores,
    );
  }

  Future<void> _save(AssignmentReview data) async {
    ref.read(saveStatusProvider.notifier).setSaving();
    try {
      final dataService = ref.read(dataServiceProvider);
      await dataService.saveAssignmentReview(_candidateId, data);
      ref.read(saveStatusProvider.notifier).setSaved();
    } catch (e) {
      ref.read(saveStatusProvider.notifier).setError();
      rethrow;
    }
  }

  /// Mark assignment as sent with optional due date.
  Future<void> markAsSent({DateTime? dueAt}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: DateTime.now(),
      dueAt: dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: AssignmentStatus.sent,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Mark assignment as submitted.
  Future<void> markAsSubmitted({
    required String repoLink,
    required bool onTime,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: DateTime.now(),
      onTime: onTime,
      repoLink: repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: AssignmentStatus.submitted,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update the assignment status.
  Future<void> updateStatus(AssignmentStatus status) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: status,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update repo link.
  Future<void> updateRepoLink(String? repoLink) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: current.assignmentStatus,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update an area score.
  Future<void> updateAreaScore(String areaId, int? score) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final areaScores = Map<String, AreaScore>.from(current.areaScores);
    final existing = areaScores[areaId];
    if (existing != null) {
      areaScores[areaId] = AreaScore(
        areaId: existing.areaId,
        displayName: existing.displayName,
        weight: existing.weight,
        score: score,
        notes: existing.notes,
      );
    }

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: current.assignmentStatus,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update area notes.
  Future<void> updateAreaNotes(String areaId, String? notes) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final areaScores = Map<String, AreaScore>.from(current.areaScores);
    final existing = areaScores[areaId];
    if (existing != null) {
      areaScores[areaId] = AreaScore(
        areaId: existing.areaId,
        displayName: existing.displayName,
        weight: existing.weight,
        score: existing.score,
        notes: notes,
      );
    }

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: current.assignmentStatus,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update git history check.
  Future<void> updateGitCheck({
    String? commitPattern,
    bool? suspicious,
    String? notes,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final existingGit = current.gitCheck ?? GitHistoryCheck();
    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: current.areaScores,
      gitCheck: GitHistoryCheck(
        commitPattern: commitPattern ?? existingGit.commitPattern,
        suspicious: suspicious ?? existingGit.suspicious,
        notes: notes ?? existingGit.notes,
      ),
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: current.assignmentStatus,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update review call notes.
  Future<void> updateReviewCallNotes(String? notes) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: notes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: current.assignmentStatus,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update fraud assessment.
  Future<void> updateFraudAssessment({
    String? level,
    String? notes,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final existingFraud = current.fraudAssessment;
    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: FraudAssessment(
        level: level ?? existingFraud?.level ?? 'genuine',
        notes: notes ?? existingFraud?.notes,
      ),
      recommendation: current.recommendation,
      assignmentStatus: current.assignmentStatus,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update recommendation.
  Future<void> updateRecommendation(String? recommendation) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Update status to reviewed if setting a recommendation
    final newStatus = recommendation != null
        ? AssignmentStatus.reviewed
        : current.assignmentStatus;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: recommendation,
      assignmentStatus: newStatus,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update on-time status.
  Future<void> updateOnTime(bool onTime) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: onTime,
      repoLink: current.repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: current.assignmentStatus,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update sent date.
  Future<void> updateSentDate(DateTime? date) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: date,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus:
          date != null ? AssignmentStatus.sent : AssignmentStatus.notSent,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update due date.
  Future<void> updateDueDate(DateTime? date) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: date,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: current.assignmentStatus,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Apply AI evaluation JSON — auto-fills scores, git check, fraud, recommendation.
  Future<void> applyAiEvaluation(Map<String, dynamic> eval) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Parse area scores from AI output
    final areaScores = Map<String, AreaScore>.from(current.areaScores);
    final aiScores = eval['areaScores'] as Map<String, dynamic>?;
    if (aiScores != null) {
      for (final entry in aiScores.entries) {
        final data = entry.value as Map<String, dynamic>;
        final existing = areaScores[entry.key];
        if (existing != null) {
          areaScores[entry.key] = AreaScore(
            areaId: existing.areaId,
            displayName: existing.displayName,
            weight: existing.weight,
            score: (data['score'] as num?)?.toInt(),
            notes: data['notes'] as String?,
          );
        }
      }
    }

    // Parse git check
    GitHistoryCheck? gitCheck = current.gitCheck;
    final aiGit = eval['gitCheck'] as Map<String, dynamic>?;
    if (aiGit != null) {
      gitCheck = GitHistoryCheck(
        commitPattern: aiGit['commitPattern'] as String? ?? 'incremental',
        suspicious: aiGit['suspicious'] as bool? ?? false,
        notes: aiGit['notes'] as String?,
      );
    }

    // Parse fraud assessment
    FraudAssessment? fraud = current.fraudAssessment;
    final aiFraud = eval['fraudAssessment'] as Map<String, dynamic>?;
    if (aiFraud != null) {
      fraud = FraudAssessment(
        level: aiFraud['level'] as String? ?? 'genuine',
        notes: aiFraud['notes'] as String?,
      );
    }

    // Parse recommendation
    final recommendation =
        eval['recommendation'] as String? ?? current.recommendation;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: current.submittedAt,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: areaScores,
      gitCheck: gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: fraud,
      recommendation: recommendation,
      assignmentStatus: current.assignmentStatus,
      aiEvaluation: eval,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Update submitted date.
  Future<void> updateSubmittedDate(DateTime? date) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final newStatus = date != null
        ? (current.recommendation != null
            ? AssignmentStatus.reviewed
            : AssignmentStatus.submitted)
        : current.assignmentStatus;

    final updated = AssignmentReview(
      candidateId: current.candidateId,
      sentAt: current.sentAt,
      dueAt: current.dueAt,
      submittedAt: date,
      onTime: current.onTime,
      repoLink: current.repoLink,
      areaScores: current.areaScores,
      gitCheck: current.gitCheck,
      reviewCallNotes: current.reviewCallNotes,
      fraudAssessment: current.fraudAssessment,
      recommendation: current.recommendation,
      assignmentStatus: newStatus,
      aiEvaluation: current.aiEvaluation,
    );
    state = AsyncData(updated);
    await _save(updated);
  }
}

final assignmentReviewNotifierProvider = AsyncNotifierProvider.family<
    AssignmentReviewNotifier, AssignmentReview, String>(
  AssignmentReviewNotifier.new,
);
