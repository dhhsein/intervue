// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interview_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InterviewQuestion _$InterviewQuestionFromJson(Map<String, dynamic> json) =>
    InterviewQuestion(
      id: json['id'] as String,
      category: json['category'] as String,
      question: json['question'] as String,
      assesses: json['assesses'] as String,
      fraudProbe: json['fraudProbe'] as String?,
      depth: json['depth'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      bank: json['bank'] as String,
      inputType: json['inputType'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      matrixOptions: json['matrixOptions'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$InterviewQuestionToJson(InterviewQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'question': instance.question,
      'assesses': instance.assesses,
      'fraudProbe': instance.fraudProbe,
      'depth': instance.depth,
      'tags': instance.tags,
      'bank': instance.bank,
      'inputType': instance.inputType,
      'options': instance.options,
      'matrixOptions': instance.matrixOptions,
    };

QuestionBank _$QuestionBankFromJson(Map<String, dynamic> json) => QuestionBank(
  questions: (json['questions'] as List<dynamic>)
      .map((e) => InterviewQuestion.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$QuestionBankToJson(QuestionBank instance) =>
    <String, dynamic>{'questions': instance.questions};
