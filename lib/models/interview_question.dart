import 'package:json_annotation/json_annotation.dart';

part 'interview_question.g.dart';

@JsonSerializable()
class InterviewQuestion {
  final String id;
  final String category;
  final String question;
  final String assesses;
  final String? fraudProbe;
  final String depth;
  final List<String> tags;
  final String bank;

  // For screening questions only
  final String? inputType;
  final List<String>? options;
  final Map<String, dynamic>? matrixOptions;

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

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) =>
      _$InterviewQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$InterviewQuestionToJson(this);
}

@JsonSerializable()
class QuestionBank {
  final List<InterviewQuestion> questions;

  QuestionBank({required this.questions});

  factory QuestionBank.fromJson(Map<String, dynamic> json) =>
      _$QuestionBankFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionBankToJson(this);
}
