// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screening_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScreeningData _$ScreeningDataFromJson(
  Map<String, dynamic> json,
) => ScreeningData(
  emailSentAt: json['emailSentAt'] == null
      ? null
      : DateTime.parse(json['emailSentAt'] as String),
  responseReceivedAt: json['responseReceivedAt'] == null
      ? null
      : DateTime.parse(json['responseReceivedAt'] as String),
  phoneScreenAt: json['phoneScreenAt'] == null
      ? null
      : DateTime.parse(json['phoneScreenAt'] as String),
  grade: $enumDecodeNullable(_$ScreeningGradeEnumMap, json['grade']),
  responses:
      (json['responses'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, ScreeningResponse.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
  phoneScreen: json['phoneScreen'] == null
      ? null
      : PhoneScreenData.fromJson(json['phoneScreen'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ScreeningDataToJson(ScreeningData instance) =>
    <String, dynamic>{
      'emailSentAt': instance.emailSentAt?.toIso8601String(),
      'responseReceivedAt': instance.responseReceivedAt?.toIso8601String(),
      'phoneScreenAt': instance.phoneScreenAt?.toIso8601String(),
      'grade': _$ScreeningGradeEnumMap[instance.grade],
      'responses': instance.responses,
      'phoneScreen': instance.phoneScreen,
    };

const _$ScreeningGradeEnumMap = {
  ScreeningGrade.strong: 'strong',
  ScreeningGrade.maybe: 'maybe',
  ScreeningGrade.no: 'no',
};

ScreeningResponse _$ScreeningResponseFromJson(Map<String, dynamic> json) =>
    ScreeningResponse(
      questionId: json['questionId'] as String,
      selectedOption: json['selectedOption'] as String?,
      selectedOptions: (json['selectedOptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      textValue: json['textValue'] as String?,
      numericValue: json['numericValue'] as String?,
      numericValue2: json['numericValue2'] as String?,
      techLevels: (json['techLevels'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ScreeningResponseToJson(ScreeningResponse instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'selectedOption': instance.selectedOption,
      'selectedOptions': instance.selectedOptions,
      'textValue': instance.textValue,
      'numericValue': instance.numericValue,
      'numericValue2': instance.numericValue2,
      'techLevels': instance.techLevels,
      'notes': instance.notes,
    };

PhoneScreenData _$PhoneScreenDataFromJson(Map<String, dynamic> json) =>
    PhoneScreenData(
      conducted: json['conducted'] as bool? ?? false,
      communicationScore: (json['communicationScore'] as num?)?.toInt(),
      salaryConfirmed: json['salaryConfirmed'] as bool? ?? false,
      noticeConfirmed: json['noticeConfirmed'] as bool? ?? false,
      onsiteConfirmed: json['onsiteConfirmed'] as bool? ?? false,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$PhoneScreenDataToJson(PhoneScreenData instance) =>
    <String, dynamic>{
      'conducted': instance.conducted,
      'communicationScore': instance.communicationScore,
      'salaryConfirmed': instance.salaryConfirmed,
      'noticeConfirmed': instance.noticeConfirmed,
      'onsiteConfirmed': instance.onsiteConfirmed,
      'notes': instance.notes,
    };
