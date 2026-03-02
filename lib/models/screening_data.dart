import 'package:json_annotation/json_annotation.dart';

part 'screening_data.g.dart';

@JsonSerializable()
class ScreeningData {
  DateTime? emailSentAt;
  DateTime? responseReceivedAt;
  DateTime? phoneScreenAt;
  ScreeningGrade? grade;
  Map<String, ScreeningResponse> responses;
  PhoneScreenData? phoneScreen;

  ScreeningData({
    this.emailSentAt,
    this.responseReceivedAt,
    this.phoneScreenAt,
    this.grade,
    this.responses = const {},
    this.phoneScreen,
  });

  factory ScreeningData.fromJson(Map<String, dynamic> json) =>
      _$ScreeningDataFromJson(json);
  Map<String, dynamic> toJson() => _$ScreeningDataToJson(this);
}

@JsonEnum(valueField: 'value')
enum ScreeningGrade {
  @JsonValue('strong')
  strong('strong'),
  @JsonValue('maybe')
  maybe('maybe'),
  @JsonValue('no')
  no('no');

  final String value;
  const ScreeningGrade(this.value);
}

@JsonSerializable()
class ScreeningResponse {
  final String questionId;
  String? selectedOption;
  List<String>? selectedOptions;
  String? textValue;
  String? numericValue;
  String? numericValue2;
  Map<String, String>? techLevels;
  String? notes;

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

  factory ScreeningResponse.fromJson(Map<String, dynamic> json) =>
      _$ScreeningResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ScreeningResponseToJson(this);
}

@JsonSerializable()
class PhoneScreenData {
  bool conducted;
  int? communicationScore;
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

  factory PhoneScreenData.fromJson(Map<String, dynamic> json) =>
      _$PhoneScreenDataFromJson(json);
  Map<String, dynamic> toJson() => _$PhoneScreenDataToJson(this);
}
