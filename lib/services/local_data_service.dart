import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/candidate.dart';
import '../models/screening_data.dart';
import '../models/technical_round.dart';
import '../models/assignment_review.dart';
import '../models/interview_question.dart';
import '../models/app_config.dart';
import 'data_service.dart';

class LocalDataService implements DataService {
  final Dio _dio;
  final String baseUrl;

  LocalDataService({
    String? baseUrl,
    Dio? dio,
  })  : baseUrl = baseUrl ?? 'http://localhost:3001',
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = this.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  @override
  Future<List<Candidate>> getCandidates() async {
    final response = await _dio.get('/api/candidates');
    final data = response.data as Map<String, dynamic>;
    final candidatesList = data['candidates'] as List<dynamic>;
    return candidatesList
        .map((json) => Candidate.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CandidateDetail> getCandidate(String id) async {
    final response = await _dio.get('/api/candidates/$id');
    final data = response.data as Map<String, dynamic>;
    return CandidateDetail.fromJson(data);
  }

  @override
  Future<Candidate> createCandidate({
    required String name,
    required String email,
    String? phone,
  }) async {
    final response = await _dio.post('/api/candidates', data: {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
    });
    return Candidate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Candidate> updateCandidate(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _dio.put('/api/candidates/$id', data: updates);
    return Candidate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCandidate(String id) async {
    await _dio.delete('/api/candidates/$id');
  }

  @override
  Future<ScreeningData?> getScreening(String candidateId) async {
    final response = await _dio.get('/api/candidates/$candidateId/screening');
    final data = response.data as Map<String, dynamic>;
    if (data['screening'] == null) return null;
    return ScreeningData.fromJson(data['screening'] as Map<String, dynamic>);
  }

  @override
  Future<ScreeningData> saveScreening(
    String candidateId,
    ScreeningData data,
  ) async {
    final response = await _dio.put(
      '/api/candidates/$candidateId/screening',
      data: data.toJson(),
    );
    return ScreeningData.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TechnicalRound?> getTechnicalRound(String candidateId) async {
    final response = await _dio.get('/api/candidates/$candidateId/technical');
    final data = response.data as Map<String, dynamic>;
    if (data['technical'] == null) return null;
    return TechnicalRound.fromJson(data['technical'] as Map<String, dynamic>);
  }

  @override
  Future<TechnicalRound> saveTechnicalRound(
    String candidateId,
    TechnicalRound data,
  ) async {
    final response = await _dio.put(
      '/api/candidates/$candidateId/technical',
      data: data.toJson(),
    );
    return TechnicalRound.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AssignmentReview?> getAssignmentReview(String candidateId) async {
    final response = await _dio.get('/api/candidates/$candidateId/assignment');
    final data = response.data as Map<String, dynamic>;
    if (data['assignment'] == null) return null;
    return AssignmentReview.fromJson(
      data['assignment'] as Map<String, dynamic>,
    );
  }

  @override
  Future<AssignmentReview> saveAssignmentReview(
    String candidateId,
    AssignmentReview data,
  ) async {
    final response = await _dio.put(
      '/api/candidates/$candidateId/assignment',
      data: data.toJson(),
    );
    return AssignmentReview.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<InterviewQuestion>> getQuestions(String bank) async {
    final response = await _dio.get('/api/questions/$bank');
    final data = response.data as Map<String, dynamic>;
    final questionsList = data['questions'] as List<dynamic>;
    return questionsList
        .map((json) => InterviewQuestion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> uploadResume(String candidateId, Uint8List bytes) async {
    final response = await _dio.post(
      '/api/candidates/$candidateId/resume',
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': 'application/pdf',
          'Content-Length': bytes.length,
        },
      ),
    );
    final data = response.data as Map<String, dynamic>;
    return data['path'] as String;
  }

  @override
  String getResumeUrl(String candidateId, String filename) {
    return '$baseUrl/api/files/candidates/$candidateId/$filename';
  }

  @override
  Future<Map<String, String?>> extractResumeInfo(String candidateId) async {
    final response = await _dio.get('/api/candidates/$candidateId/resume/extract');
    return Map<String, String?>.from(response.data as Map);
  }

  @override
  Future<Map<String, String?>> extractResumeFromBytes(Uint8List bytes) async {
    final response = await _dio.post(
      '/api/resume/extract',
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': 'application/pdf',
          'Content-Length': bytes.length,
        },
      ),
    );
    return Map<String, String?>.from(response.data as Map);
  }

  @override
  Future<AppConfig> getConfig() async {
    final response = await _dio.get('/api/config');
    return AppConfig.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AppConfig> saveConfig(AppConfig config) async {
    final response = await _dio.put('/api/config', data: config.toJson());
    return AppConfig.fromJson(response.data as Map<String, dynamic>);
  }
}
