import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/candidate/candidate_detail_screen.dart';
import '../screens/interview/question_bank_screen.dart';
import '../screens/interview/interview_session_screen.dart';
import '../screens/interview/interview_summary_screen.dart';
import '../screens/compare/compare_screen.dart';
import '../screens/rejected/rejected_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/candidate/:id',
        name: 'candidateDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CandidateDetailScreen(candidateId: id);
        },
      ),
      GoRoute(
        path: '/candidate/:id/questions',
        name: 'questionBank',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QuestionBankScreen(candidateId: id);
        },
      ),
      GoRoute(
        path: '/candidate/:id/interview',
        name: 'interviewSession',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InterviewSessionScreen(candidateId: id);
        },
      ),
      GoRoute(
        path: '/candidate/:id/interview/summary',
        name: 'interviewSummary',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InterviewSummaryScreen(candidateId: id);
        },
      ),
      GoRoute(
        path: '/compare',
        name: 'compare',
        builder: (context, state) => const CompareScreen(),
      ),
      GoRoute(
        path: '/rejected',
        name: 'rejected',
        builder: (context, state) => const RejectedScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
