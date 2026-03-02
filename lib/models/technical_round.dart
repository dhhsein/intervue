import 'package:json_annotation/json_annotation.dart';

part 'technical_round.g.dart';

@JsonSerializable()
class TechnicalRound {
  String candidateId;
  DateTime date;
  int durationSeconds;
  List<QuestionScore> questions;
  OverallImpressions? impressions;
  FraudAssessment? fraudAssessment;
  String? recommendation;
  bool completed;

  TechnicalRound({
    required this.candidateId,
    required this.date,
    this.durationSeconds = 0,
    this.questions = const [],
    this.impressions,
    this.fraudAssessment,
    this.recommendation,
    this.completed = false,
  });

  double get averageScore {
    final scored = questions.where((q) => q.score != null && q.score! > 0);
    if (scored.isEmpty) return 0;
    return scored.map((q) => q.score!).reduce((a, b) => a + b) / scored.length;
  }

  factory TechnicalRound.fromJson(Map<String, dynamic> json) =>
      _$TechnicalRoundFromJson(json);
  Map<String, dynamic> toJson() => _$TechnicalRoundToJson(this);
}

@JsonSerializable()
class QuestionScore {
  String questionId;
  int? score;
  FraudFlag fraudFlag;
  String? responseQuality;
  String? responseSummary;
  String? notes;
  bool skipped;

  QuestionScore({
    required this.questionId,
    this.score,
    this.fraudFlag = FraudFlag.none,
    this.responseQuality,
    this.responseSummary,
    this.notes,
    this.skipped = false,
  });

  factory QuestionScore.fromJson(Map<String, dynamic> json) =>
      _$QuestionScoreFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionScoreToJson(this);
}

@JsonEnum(valueField: 'value')
enum FraudFlag {
  @JsonValue('none')
  none('none'),
  @JsonValue('concern')
  concern('concern'),
  @JsonValue('suspect')
  suspect('suspect');

  final String value;
  const FraudFlag(this.value);
}

@JsonSerializable()
class OverallImpressions {
  int? communication;
  int? depthOfKnowledge;
  int? problemSolving;
  int? cultureFit;
  String? redFlags;
  String? greenFlags;

  OverallImpressions({
    this.communication,
    this.depthOfKnowledge,
    this.problemSolving,
    this.cultureFit,
    this.redFlags,
    this.greenFlags,
  });

  double get average {
    final scores = [communication, depthOfKnowledge, problemSolving, cultureFit]
        .whereType<int>()
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  factory OverallImpressions.fromJson(Map<String, dynamic> json) =>
      _$OverallImpressionsFromJson(json);
  Map<String, dynamic> toJson() => _$OverallImpressionsToJson(this);
}

@JsonSerializable()
class FraudAssessment {
  String level;
  String? notes;

  FraudAssessment({
    required this.level,
    this.notes,
  });

  factory FraudAssessment.fromJson(Map<String, dynamic> json) =>
      _$FraudAssessmentFromJson(json);
  Map<String, dynamic> toJson() => _$FraudAssessmentToJson(this);
}
