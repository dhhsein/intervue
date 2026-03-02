import 'dart:typed_data';

import '../models/candidate.dart';
import '../models/screening_data.dart';
import '../models/technical_round.dart';
import '../models/assignment_review.dart';
import '../models/interview_question.dart';
import '../models/app_config.dart';

abstract class DataService {
  // Candidates
  Future<List<Candidate>> getCandidates();
  Future<CandidateDetail> getCandidate(String id);
  Future<Candidate> createCandidate({
    required String name,
    required String email,
    String? phone,
  });
  Future<Candidate> updateCandidate(String id, Map<String, dynamic> updates);
  Future<void> deleteCandidate(String id);

  // Screening
  Future<ScreeningData?> getScreening(String candidateId);
  Future<ScreeningData> saveScreening(String candidateId, ScreeningData data);

  // Technical Round
  Future<TechnicalRound?> getTechnicalRound(String candidateId);
  Future<TechnicalRound> saveTechnicalRound(
    String candidateId,
    TechnicalRound data,
  );

  // Assignment
  Future<AssignmentReview?> getAssignmentReview(String candidateId);
  Future<AssignmentReview> saveAssignmentReview(
    String candidateId,
    AssignmentReview data,
  );

  // Questions
  Future<List<InterviewQuestion>> getQuestions(String bank);

  // Files
  Future<String> uploadResume(String candidateId, Uint8List bytes);
  String getResumeUrl(String candidateId, String filename);

  /// Extract contact info (email, phone) from uploaded resume
  Future<Map<String, String?>> extractResumeInfo(String candidateId);

  // Config
  Future<AppConfig> getConfig();
  Future<AppConfig> saveConfig(AppConfig config);
}
