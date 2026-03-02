// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => AppConfig(
  interviewerName: json['interviewerName'] as String? ?? 'Your Name',
  companyName: json['companyName'] as String? ?? 'Acrophase',
  roleName: json['roleName'] as String? ?? 'Python Backend Engineer',
  location: json['location'] as String?,
  emailTemplate: json['emailTemplate'] as String?,
  rejectionTemplate: json['rejectionTemplate'] as String?,
  assignmentBrief: json['assignmentBrief'] as String?,
  serverPort: (json['serverPort'] as num?)?.toInt() ?? 3001,
);

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
  'interviewerName': instance.interviewerName,
  'companyName': instance.companyName,
  'roleName': instance.roleName,
  'location': instance.location,
  'emailTemplate': instance.emailTemplate,
  'rejectionTemplate': instance.rejectionTemplate,
  'assignmentBrief': instance.assignmentBrief,
  'serverPort': instance.serverPort,
};
