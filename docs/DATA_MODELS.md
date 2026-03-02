# InterVue — Data Models

All models use `json_serializable` for serialization. Field names in JSON use camelCase.

---

## Candidate

The core entity. One candidate = one folder in the data directory.

```dart
import 'package:json_annotation/json_annotation.dart';

part 'candidate.g.dart';

@JsonSerializable()
class Candidate {
  final String id;               // "c_20250301_arjun_mehta" — generated from date + name
  String name;
  String email;
  String? phone;
  String? resumePath;             // relative path: "candidates/c_.../resume.pdf"
  CandidateStatus status;
  DateTime createdAt;
  DateTime updatedAt;
  ScreeningData? screening;
  String? rejectionReason;
  List<StatusChange> timeline;    // log of all status changes

  Candidate({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.resumePath,
    this.status = CandidateStatus.newCandidate,
    required this.createdAt,
    required this.updatedAt,
    this.screening,
    this.rejectionReason,
    this.timeline = const [],
  });

  factory Candidate.fromJson(Map<String, dynamic> json) => _$CandidateFromJson(json);
  Map<String, dynamic> toJson() => _$CandidateToJson(this);
}

@JsonEnum(valueField: 'value')
enum CandidateStatus {
  newCandidate('new'),
  screeningSent('screening_sent'),
  screeningDone('screening_done'),
  phoneScreen('phone_screen'),
  technical('technical'),
  assignment('assignment'),
  finalReview('final_review'),
  offer('offer'),
  hired('hired'),
  rejected('rejected');

  final String value;
  const CandidateStatus(this.value);

  String get displayName {
    switch (this) {
      case CandidateStatus.newCandidate: return 'New';
      case CandidateStatus.screeningSent: return 'Screening Sent';
      case CandidateStatus.screeningDone: return 'Screening Done';
      case CandidateStatus.phoneScreen: return 'Phone Screen';
      case CandidateStatus.technical: return 'Technical';
      case CandidateStatus.assignment: return 'Assignment';
      case CandidateStatus.finalReview: return 'Final Review';
      case CandidateStatus.offer: return 'Offer';
      case CandidateStatus.hired: return 'Hired';
      case CandidateStatus.rejected: return 'Rejected';
    }
  }

  /// Which pipeline column this status belongs to
  PipelineStage get pipelineStage {
    switch (this) {
      case CandidateStatus.newCandidate:
      case CandidateStatus.screeningSent:
      case CandidateStatus.screeningDone:
      case CandidateStatus.phoneScreen:
        return PipelineStage.screening;
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
  final CandidateStatus from;
  final CandidateStatus to;
  final DateTime at;
  final String? note;

  StatusChange({required this.from, required this.to, required this.at, this.note});

  factory StatusChange.fromJson(Map<String, dynamic> json) => _$StatusChangeFromJson(json);
  Map<String, dynamic> toJson() => _$StatusChangeToJson(this);
}
```

---

## Screening Data

Stored in the candidate's `screening.json` file.

```dart
@JsonSerializable()
class ScreeningData {
  DateTime? emailSentAt;
  DateTime? responseReceivedAt;
  DateTime? phoneScreenAt;
  ScreeningGrade? grade;                    // strong, maybe, no
  Map<String, ScreeningResponse> responses; // questionId → response
  PhoneScreenData? phoneScreen;

  ScreeningData({
    this.emailSentAt,
    this.responseReceivedAt,
    this.phoneScreenAt,
    this.grade,
    this.responses = const {},
    this.phoneScreen,
  });

  factory ScreeningData.fromJson(Map<String, dynamic> json) => _$ScreeningDataFromJson(json);
  Map<String, dynamic> toJson() => _$ScreeningDataToJson(this);
}

@JsonEnum(valueField: 'value')
enum ScreeningGrade {
  strong('strong'),
  maybe('maybe'),
  no('no');

  final String value;
  const ScreeningGrade(this.value);
}

@JsonSerializable()
class ScreeningResponse {
  final String questionId;
  String? selectedOption;           // for chip-based questions
  List<String>? selectedOptions;    // for multi-select questions
  String? textValue;                // for text/number fields
  String? numericValue;             // for CTC, notice period
  String? numericValue2;            // for expected CTC
  Map<String, String>? techLevels;  // for Q9: {"fastapi": "advanced", ...}
  String? notes;                    // interviewer's notes for this question

  ScreeningResponse({
    required this.questionId,
    this.selectedOption,
    this.selectedOptions,
    this.textValue,
    this.numericValue,
    this.numericValue2,
    this.techLevels,
    this.notes,
  });

  factory ScreeningResponse.fromJson(Map<String, dynamic> json) => _$ScreeningResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ScreeningResponseToJson(this);
}

@JsonSerializable()
class PhoneScreenData {
  bool conducted;
  int? communicationScore;        // 1-5
  bool salaryConfirmed;
  bool noticeConfirmed;
  bool onsiteConfirmed;
  String? notes;

  PhoneScreenData({
    this.conducted = false,
    this.communicationScore,
    this.salaryConfirmed = false,
    this.noticeConfirmed = false,
    this.onsiteConfirmed = false,
    this.notes,
  });

  factory PhoneScreenData.fromJson(Map<String, dynamic> json) => _$PhoneScreenDataFromJson(json);
  Map<String, dynamic> toJson() => _$PhoneScreenDataToJson(this);
}
```

---

## Technical Round

Stored in the candidate's `technical.json` file.

```dart
@JsonSerializable()
class TechnicalRound {
  String candidateId;
  DateTime date;
  int durationSeconds;              // from the timer
  List<QuestionScore> questions;
  OverallImpressions? impressions;
  FraudAssessment? fraudAssessment;
  String? recommendation;           // "advance" / "hold" / "reject"
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

  factory TechnicalRound.fromJson(Map<String, dynamic> json) => _$TechnicalRoundFromJson(json);
  Map<String, dynamic> toJson() => _$TechnicalRoundToJson(this);
}

@JsonSerializable()
class QuestionScore {
  String questionId;                // references question bank
  int? score;                       // 1-5, null if not scored yet
  FraudFlag fraudFlag;              // none, concern, suspect
  String? responseQuality;          // "detailed", "textbook", "vague", "wrong", "no_answer"
  String? responseSummary;          // what they said
  String? notes;                    // interviewer's observations
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

  factory QuestionScore.fromJson(Map<String, dynamic> json) => _$QuestionScoreFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionScoreToJson(this);
}

@JsonEnum(valueField: 'value')
enum FraudFlag {
  none('none'),
  concern('concern'),
  suspect('suspect');

  final String value;
  const FraudFlag(this.value);
}

@JsonSerializable()
class OverallImpressions {
  int? communication;               // 1-5
  int? depthOfKnowledge;            // 1-5
  int? problemSolving;              // 1-5
  int? cultureFit;                  // 1-5
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
        .whereType<int>().toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  factory OverallImpressions.fromJson(Map<String, dynamic> json) => _$OverallImpressionsFromJson(json);
  Map<String, dynamic> toJson() => _$OverallImpressionsToJson(this);
}

@JsonSerializable()
class FraudAssessment {
  String level;                     // "genuine", "some_doubt", "high_suspicion"
  String? notes;

  FraudAssessment({required this.level, this.notes});

  factory FraudAssessment.fromJson(Map<String, dynamic> json) => _$FraudAssessmentFromJson(json);
  Map<String, dynamic> toJson() => _$FraudAssessmentToJson(this);
}
```

---

## Assignment Review

Stored in the candidate's `assignment.json` file.

```dart
@JsonSerializable()
class AssignmentReview {
  String candidateId;
  DateTime? sentAt;
  DateTime? dueAt;
  DateTime? submittedAt;
  bool onTime;
  String? repoLink;
  Map<String, AreaScore> areaScores;    // "codeQuality", "correctness", etc.
  GitHistoryCheck? gitCheck;
  String? reviewCallNotes;
  FraudAssessment? fraudAssessment;
  String? recommendation;               // "hire" / "hold" / "reject"
  AssignmentStatus assignmentStatus;

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

  factory AssignmentReview.fromJson(Map<String, dynamic> json) => _$AssignmentReviewFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentReviewToJson(this);
}

@JsonEnum(valueField: 'value')
enum AssignmentStatus {
  notSent('not_sent'),
  sent('sent'),
  submitted('submitted'),
  reviewed('reviewed');

  final String value;
  const AssignmentStatus(this.value);
}

@JsonSerializable()
class AreaScore {
  String areaId;                    // "codeQuality", "correctness", etc.
  String displayName;               // "Code Quality"
  int weight;                       // percentage: 25, 20, 15, etc.
  int? score;                       // 1-5
  String? notes;

  AreaScore({
    required this.areaId,
    required this.displayName,
    required this.weight,
    this.score,
    this.notes,
  });

  factory AreaScore.fromJson(Map<String, dynamic> json) => _$AreaScoreFromJson(json);
  Map<String, dynamic> toJson() => _$AreaScoreToJson(this);
}

@JsonSerializable()
class GitHistoryCheck {
  String commitPattern;             // "incremental", "bulk", "single"
  bool suspicious;
  String? notes;

  GitHistoryCheck({
    this.commitPattern = 'incremental',
    this.suspicious = false,
    this.notes,
  });

  factory GitHistoryCheck.fromJson(Map<String, dynamic> json) => _$GitHistoryCheckFromJson(json);
  Map<String, dynamic> toJson() => _$GitHistoryCheckToJson(this);
}
```

---

## Question Bank

Loaded from JSON files in the `questions/` folder. Read-only in the app.

```dart
@JsonSerializable()
class InterviewQuestion {
  final String id;                  // "tech_python_01", "general_01", "screening_01"
  final String category;            // "Python Fundamentals", "Auth & Security", etc.
  final String question;            // full question text
  final String assesses;            // what it evaluates
  final String? fraudProbe;         // how to catch AI cheating (technical questions only)
  final String depth;               // "core" / "nice_to_have" (technical) or "screening" / "general"
  final List<String> tags;          // for filtering
  final String bank;                // "screening", "technical", "general"

  // For screening questions only:
  final String? inputType;          // "single_select", "multi_select", "number", "number_pair", "tech_matrix", "text"
  final List<String>? options;      // preset options for chip-based inputs
  final Map<String, List<String>>? matrixOptions; // for tech_matrix type (Q9)

  InterviewQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.assesses,
    this.fraudProbe,
    required this.depth,
    this.tags = const [],
    required this.bank,
    this.inputType,
    this.options,
    this.matrixOptions,
  });

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) => _$InterviewQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$InterviewQuestionToJson(this);
}
```

---

## DataService Abstract Class

All data access goes through this. Enables Firebase migration later.

```dart
abstract class DataService {
  // Candidates
  Future<List<Candidate>> getCandidates();
  Future<Candidate> getCandidate(String id);
  Future<Candidate> createCandidate(Candidate candidate);
  Future<Candidate> updateCandidate(Candidate candidate);
  Future<void> deleteCandidate(String id);

  // Screening
  Future<ScreeningData?> getScreening(String candidateId);
  Future<void> saveScreening(String candidateId, ScreeningData data);

  // Technical Round
  Future<TechnicalRound?> getTechnicalRound(String candidateId);
  Future<void> saveTechnicalRound(String candidateId, TechnicalRound data);

  // Assignment
  Future<AssignmentReview?> getAssignmentReview(String candidateId);
  Future<void> saveAssignmentReview(String candidateId, AssignmentReview data);

  // Questions
  Future<List<InterviewQuestion>> getQuestions(String bank); // "screening", "technical", "general"

  // Files
  Future<String> uploadResume(String candidateId, List<int> bytes, String filename);
  String getResumeUrl(String candidateId, String filename);
}
```
