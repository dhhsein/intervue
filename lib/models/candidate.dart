import 'package:json_annotation/json_annotation.dart';
import 'screening_data.dart';
import 'technical_round.dart';
import 'assignment_review.dart';

part 'candidate.g.dart';

@JsonSerializable()
class Candidate {
  final String id;
  String name;
  String email;
  String? phone;
  String? resumePath;
  CandidateStatus status;
  DateTime createdAt;
  DateTime updatedAt;
  String? rejectionReason;
  List<StatusChange> timeline;

  // Computed fields from related data (populated by API)
  @JsonKey(includeFromJson: true, includeToJson: false)
  String? screeningGrade;
  @JsonKey(includeFromJson: true, includeToJson: false)
  double? technicalScore;
  @JsonKey(includeFromJson: true, includeToJson: false)
  String? technicalRecommendation;
  @JsonKey(includeFromJson: true, includeToJson: false)
  double? assignmentScore;

  Candidate({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.resumePath,
    this.status = CandidateStatus.newCandidate,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionReason,
    this.timeline = const [],
    this.screeningGrade,
    this.technicalScore,
    this.technicalRecommendation,
    this.assignmentScore,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) =>
      _$CandidateFromJson(json);
  Map<String, dynamic> toJson() => _$CandidateToJson(this);
}

@JsonEnum(valueField: 'value')
enum CandidateStatus {
  @JsonValue('new')
  newCandidate('new'),
  @JsonValue('screening_sent')
  screeningSent('screening_sent'),
  @JsonValue('screening_done')
  screeningDone('screening_done'),
  @JsonValue('phone_screen')
  phoneScreen('phone_screen'),
  @JsonValue('pending_scheduling')
  pendingScheduling('pending_scheduling'),
  @JsonValue('technical')
  technical('technical'),
  @JsonValue('assignment')
  assignment('assignment'),
  @JsonValue('final_review')
  finalReview('final_review'),
  @JsonValue('offer')
  offer('offer'),
  @JsonValue('hired')
  hired('hired'),
  @JsonValue('rejected')
  rejected('rejected');

  final String value;
  const CandidateStatus(this.value);

  String get displayName {
    switch (this) {
      case CandidateStatus.newCandidate:
        return 'New';
      case CandidateStatus.screeningSent:
        return 'Screening Sent';
      case CandidateStatus.screeningDone:
        return 'Screening Done';
      case CandidateStatus.phoneScreen:
        return 'Phone Screen';
      case CandidateStatus.pendingScheduling:
        return 'Pending Scheduling';
      case CandidateStatus.technical:
        return 'Technical';
      case CandidateStatus.assignment:
        return 'Assignment';
      case CandidateStatus.finalReview:
        return 'Final Review';
      case CandidateStatus.offer:
        return 'Offer';
      case CandidateStatus.hired:
        return 'Hired';
      case CandidateStatus.rejected:
        return 'Rejected';
    }
  }

  PipelineStage get pipelineStage {
    switch (this) {
      case CandidateStatus.newCandidate:
      case CandidateStatus.screeningSent:
      case CandidateStatus.screeningDone:
      case CandidateStatus.phoneScreen:
        return PipelineStage.screening;
      case CandidateStatus.pendingScheduling:
      case CandidateStatus.technical:
        return PipelineStage.technical;
      case CandidateStatus.assignment:
        return PipelineStage.assignment;
      case CandidateStatus.finalReview:
      case CandidateStatus.offer:
        return PipelineStage.finalReview;
      case CandidateStatus.hired:
        return PipelineStage.hired;
      case CandidateStatus.rejected:
        return PipelineStage.rejected;
    }
  }
}

enum PipelineStage { screening, technical, assignment, finalReview, hired, rejected }

@JsonSerializable()
class StatusChange {
  final String from;
  final String to;
  final DateTime at;
  final String? note;

  StatusChange({
    required this.from,
    required this.to,
    required this.at,
    this.note,
  });

  factory StatusChange.fromJson(Map<String, dynamic> json) =>
      _$StatusChangeFromJson(json);
  Map<String, dynamic> toJson() => _$StatusChangeToJson(this);
}

@JsonSerializable()
class CandidateDetail {
  final Candidate candidate;
  final ScreeningData? screening;
  final TechnicalRound? technical;
  final AssignmentReview? assignment;

  CandidateDetail({
    required this.candidate,
    this.screening,
    this.technical,
    this.assignment,
  });

  factory CandidateDetail.fromJson(Map<String, dynamic> json) =>
      _$CandidateDetailFromJson(json);
  Map<String, dynamic> toJson() => _$CandidateDetailToJson(this);
}
