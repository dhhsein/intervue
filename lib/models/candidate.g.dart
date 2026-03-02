// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Candidate _$CandidateFromJson(Map<String, dynamic> json) => Candidate(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  resumePath: json['resumePath'] as String?,
  status:
      $enumDecodeNullable(_$CandidateStatusEnumMap, json['status']) ??
      CandidateStatus.newCandidate,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  rejectionReason: json['rejectionReason'] as String?,
  timeline:
      (json['timeline'] as List<dynamic>?)
          ?.map((e) => StatusChange.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  screeningGrade: json['screeningGrade'] as String?,
  technicalScore: (json['technicalScore'] as num?)?.toDouble(),
  assignmentScore: (json['assignmentScore'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CandidateToJson(Candidate instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'resumePath': instance.resumePath,
  'status': _$CandidateStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'rejectionReason': instance.rejectionReason,
  'timeline': instance.timeline,
};

const _$CandidateStatusEnumMap = {
  CandidateStatus.newCandidate: 'new',
  CandidateStatus.screeningSent: 'screening_sent',
  CandidateStatus.screeningDone: 'screening_done',
  CandidateStatus.phoneScreen: 'phone_screen',
  CandidateStatus.technical: 'technical',
  CandidateStatus.assignment: 'assignment',
  CandidateStatus.finalReview: 'final_review',
  CandidateStatus.offer: 'offer',
  CandidateStatus.hired: 'hired',
  CandidateStatus.rejected: 'rejected',
};

StatusChange _$StatusChangeFromJson(Map<String, dynamic> json) => StatusChange(
  from: json['from'] as String,
  to: json['to'] as String,
  at: DateTime.parse(json['at'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$StatusChangeToJson(StatusChange instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'at': instance.at.toIso8601String(),
      'note': instance.note,
    };

CandidateDetail _$CandidateDetailFromJson(Map<String, dynamic> json) =>
    CandidateDetail(
      candidate: Candidate.fromJson(json['candidate'] as Map<String, dynamic>),
      screening: json['screening'] == null
          ? null
          : ScreeningData.fromJson(json['screening'] as Map<String, dynamic>),
      technical: json['technical'] == null
          ? null
          : TechnicalRound.fromJson(json['technical'] as Map<String, dynamic>),
      assignment: json['assignment'] == null
          ? null
          : AssignmentReview.fromJson(
              json['assignment'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CandidateDetailToJson(CandidateDetail instance) =>
    <String, dynamic>{
      'candidate': instance.candidate,
      'screening': instance.screening,
      'technical': instance.technical,
      'assignment': instance.assignment,
    };
