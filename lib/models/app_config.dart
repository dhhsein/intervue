import 'package:json_annotation/json_annotation.dart';

part 'app_config.g.dart';

@JsonSerializable()
class AppConfig {
  String interviewerName;
  String companyName;
  String roleName;
  String? location;
  String? emailTemplate;
  String? rejectionTemplate;
  String? assignmentBrief;
  int serverPort;

  AppConfig({
    this.interviewerName = 'Your Name',
    this.companyName = 'Acrophase',
    this.roleName = 'Python Backend Engineer',
    this.location,
    this.emailTemplate,
    this.rejectionTemplate,
    this.assignmentBrief,
    this.serverPort = 3001,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AppConfigToJson(this);
}
