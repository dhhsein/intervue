// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technical_round.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicalRound _$TechnicalRoundFromJson(Map<String, dynamic> json) =>
    TechnicalRound(
      candidateId: json['candidateId'] as String,
      date: DateTime.parse(json['date'] as String),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      impressions: json['impressions'] == null
          ? null
          : OverallImpressions.fromJson(
              json['impressions'] as Map<String, dynamic>,
            ),
      fraudAssessment: json['fraudAssessment'] == null
          ? null
          : FraudAssessment.fromJson(
              json['fraudAssessment'] as Map<String, dynamic>,
            ),
      recommendation: json['recommendation'] as String?,
      completed: json['completed'] as bool? ?? false,
    );

Map<String, dynamic> _$TechnicalRoundToJson(TechnicalRound instance) =>
    <String, dynamic>{
      'candidateId': instance.candidateId,
      'date': instance.date.toIso8601String(),
      'durationSeconds': instance.durationSeconds,
      'questions': instance.questions,
      'impressions': instance.impressions,
      'fraudAssessment': instance.fraudAssessment,
      'recommendation': instance.recommendation,
      'completed': instance.completed,
    };

QuestionScore _$QuestionScoreFromJson(Map<String, dynamic> json) =>
    QuestionScore(
      questionId: json['questionId'] as String,
      score: (json['score'] as num?)?.toInt(),
      fraudFlag:
          $enumDecodeNullable(_$FraudFlagEnumMap, json['fraudFlag']) ??
          FraudFlag.none,
      responseQuality: json['responseQuality'] as String?,
      responseSummary: json['responseSummary'] as String?,
      notes: json['notes'] as String?,
      skipped: json['skipped'] as bool? ?? false,
    );

Map<String, dynamic> _$QuestionScoreToJson(QuestionScore instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'score': instance.score,
      'fraudFlag': _$FraudFlagEnumMap[instance.fraudFlag]!,
      'responseQuality': instance.responseQuality,
      'responseSummary': instance.responseSummary,
      'notes': instance.notes,
      'skipped': instance.skipped,
    };

const _$FraudFlagEnumMap = {
  FraudFlag.none: 'none',
  FraudFlag.concern: 'concern',
  FraudFlag.suspect: 'suspect',
};

OverallImpressions _$OverallImpressionsFromJson(Map<String, dynamic> json) =>
    OverallImpressions(
      communication: (json['communication'] as num?)?.toInt(),
      depthOfKnowledge: (json['depthOfKnowledge'] as num?)?.toInt(),
      problemSolving: (json['problemSolving'] as num?)?.toInt(),
      cultureFit: (json['cultureFit'] as num?)?.toInt(),
      redFlags: json['redFlags'] as String?,
      greenFlags: json['greenFlags'] as String?,
    );

Map<String, dynamic> _$OverallImpressionsToJson(OverallImpressions instance) =>
    <String, dynamic>{
      'communication': instance.communication,
      'depthOfKnowledge': instance.depthOfKnowledge,
      'problemSolving': instance.problemSolving,
      'cultureFit': instance.cultureFit,
      'redFlags': instance.redFlags,
      'greenFlags': instance.greenFlags,
    };

FraudAssessment _$FraudAssessmentFromJson(Map<String, dynamic> json) =>
    FraudAssessment(
      level: json['level'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$FraudAssessmentToJson(FraudAssessment instance) =>
    <String, dynamic>{'level': instance.level, 'notes': instance.notes};
