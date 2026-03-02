// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentReview _$AssignmentReviewFromJson(Map<String, dynamic> json) =>
    AssignmentReview(
      candidateId: json['candidateId'] as String,
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
      dueAt: json['dueAt'] == null
          ? null
          : DateTime.parse(json['dueAt'] as String),
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.parse(json['submittedAt'] as String),
      onTime: json['onTime'] as bool? ?? false,
      repoLink: json['repoLink'] as String?,
      areaScores:
          (json['areaScores'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, AreaScore.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      gitCheck: json['gitCheck'] == null
          ? null
          : GitHistoryCheck.fromJson(json['gitCheck'] as Map<String, dynamic>),
      reviewCallNotes: json['reviewCallNotes'] as String?,
      fraudAssessment: json['fraudAssessment'] == null
          ? null
          : FraudAssessment.fromJson(
              json['fraudAssessment'] as Map<String, dynamic>,
            ),
      recommendation: json['recommendation'] as String?,
      assignmentStatus:
          $enumDecodeNullable(
            _$AssignmentStatusEnumMap,
            json['assignmentStatus'],
          ) ??
          AssignmentStatus.notSent,
    );

Map<String, dynamic> _$AssignmentReviewToJson(AssignmentReview instance) =>
    <String, dynamic>{
      'candidateId': instance.candidateId,
      'sentAt': instance.sentAt?.toIso8601String(),
      'dueAt': instance.dueAt?.toIso8601String(),
      'submittedAt': instance.submittedAt?.toIso8601String(),
      'onTime': instance.onTime,
      'repoLink': instance.repoLink,
      'areaScores': instance.areaScores,
      'gitCheck': instance.gitCheck,
      'reviewCallNotes': instance.reviewCallNotes,
      'fraudAssessment': instance.fraudAssessment,
      'recommendation': instance.recommendation,
      'assignmentStatus': _$AssignmentStatusEnumMap[instance.assignmentStatus]!,
    };

const _$AssignmentStatusEnumMap = {
  AssignmentStatus.notSent: 'not_sent',
  AssignmentStatus.sent: 'sent',
  AssignmentStatus.submitted: 'submitted',
  AssignmentStatus.reviewed: 'reviewed',
};

AreaScore _$AreaScoreFromJson(Map<String, dynamic> json) => AreaScore(
  areaId: json['areaId'] as String,
  displayName: json['displayName'] as String,
  weight: (json['weight'] as num).toInt(),
  score: (json['score'] as num?)?.toInt(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$AreaScoreToJson(AreaScore instance) => <String, dynamic>{
  'areaId': instance.areaId,
  'displayName': instance.displayName,
  'weight': instance.weight,
  'score': instance.score,
  'notes': instance.notes,
};

GitHistoryCheck _$GitHistoryCheckFromJson(Map<String, dynamic> json) =>
    GitHistoryCheck(
      commitPattern: json['commitPattern'] as String? ?? 'incremental',
      suspicious: json['suspicious'] as bool? ?? false,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$GitHistoryCheckToJson(GitHistoryCheck instance) =>
    <String, dynamic>{
      'commitPattern': instance.commitPattern,
      'suspicious': instance.suspicious,
      'notes': instance.notes,
    };
