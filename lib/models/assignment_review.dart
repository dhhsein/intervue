import 'package:json_annotation/json_annotation.dart';
import 'technical_round.dart';

part 'assignment_review.g.dart';

@JsonSerializable()
class AssignmentReview {
  String candidateId;
  DateTime? sentAt;
  DateTime? dueAt;
  DateTime? submittedAt;
  bool onTime;
  String? repoLink;
  Map<String, AreaScore> areaScores;
  GitHistoryCheck? gitCheck;
  String? reviewCallNotes;
  FraudAssessment? fraudAssessment;
  String? recommendation;
  AssignmentStatus assignmentStatus;
  Map<String, dynamic>? aiEvaluation;

  AssignmentReview({
    required this.candidateId,
    this.sentAt,
    this.dueAt,
    this.submittedAt,
    this.onTime = false,
    this.repoLink,
    this.areaScores = const {},
    this.gitCheck,
    this.reviewCallNotes,
    this.fraudAssessment,
    this.recommendation,
    this.assignmentStatus = AssignmentStatus.notSent,
    this.aiEvaluation,
  });

  double get weightedScore {
    if (areaScores.isEmpty) return 0;
    double total = 0;
    double weightSum = 0;
    for (final entry in areaScores.values) {
      if (entry.score != null) {
        total += entry.score! * (entry.weight / 100);
        weightSum += entry.weight / 100;
      }
    }
    return weightSum > 0 ? total / weightSum : 0;
  }

  factory AssignmentReview.fromJson(Map<String, dynamic> json) =>
      _$AssignmentReviewFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentReviewToJson(this);
}

@JsonEnum(valueField: 'value')
enum AssignmentStatus {
  @JsonValue('not_sent')
  notSent('not_sent'),
  @JsonValue('sent')
  sent('sent'),
  @JsonValue('submitted')
  submitted('submitted'),
  @JsonValue('reviewed')
  reviewed('reviewed');

  final String value;
  const AssignmentStatus(this.value);
}

@JsonSerializable()
class AreaScore {
  String areaId;
  String displayName;
  int weight;
  int? score;
  String? notes;

  AreaScore({
    required this.areaId,
    required this.displayName,
    required this.weight,
    this.score,
    this.notes,
  });

  factory AreaScore.fromJson(Map<String, dynamic> json) =>
      _$AreaScoreFromJson(json);
  Map<String, dynamic> toJson() => _$AreaScoreToJson(this);
}

@JsonSerializable()
class GitHistoryCheck {
  String commitPattern;
  bool suspicious;
  String? notes;

  GitHistoryCheck({
    this.commitPattern = 'incremental',
    this.suspicious = false,
    this.notes,
  });

  factory GitHistoryCheck.fromJson(Map<String, dynamic> json) =>
      _$GitHistoryCheckFromJson(json);
  Map<String, dynamic> toJson() => _$GitHistoryCheckToJson(this);
}
