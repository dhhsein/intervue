import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:intervue_server/resume_parser.dart';

late String dataDir;
late String seedDataDir;

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '3001')
    ..addOption('data-dir', defaultsTo: '${Platform.environment['HOME']}/intervue_data');

  final results = parser.parse(args);
  final port = int.parse(results['port'] as String);
  dataDir = results['data-dir'] as String;

  final scriptDir = path.dirname(Platform.script.toFilePath());
  seedDataDir = path.normalize(path.join(scriptDir, '..', '..', 'seed_data'));

  await initializeDataDir();

  final app = Router();

  app.get('/api/candidates', _getCandidates);
  app.get('/api/candidates/<id>', _getCandidate);
  app.post('/api/candidates', _createCandidate);
  app.put('/api/candidates/<id>', _updateCandidate);
  app.delete('/api/candidates/<id>', _deleteCandidate);

  app.get('/api/candidates/<id>/screening', _getScreening);
  app.put('/api/candidates/<id>/screening', _saveScreening);

  app.get('/api/candidates/<id>/technical', _getTechnical);
  app.put('/api/candidates/<id>/technical', _saveTechnical);

  app.get('/api/candidates/<id>/assignment', _getAssignment);
  app.put('/api/candidates/<id>/assignment', _saveAssignment);

  app.get('/api/questions/<bank>', _getQuestions);

  app.post('/api/candidates/<id>/resume', _uploadResume);
  app.get('/api/candidates/<id>/resume/extract', _extractResumeInfo);
  app.get('/api/files/<path|.*>', _serveFile);

  app.get('/api/config', _getConfig);
  app.put('/api/config', _saveConfig);

  final handler = const Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(app.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  // ignore: avoid_print
  print('InterVue server running on http://localhost:${server.port}');
  // ignore: avoid_print
  print('Data directory: $dataDir');
}

Middleware _corsMiddleware() {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };

  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }
      final response = await handler(request);
      return response.change(headers: corsHeaders);
    };
  };
}

Future<void> initializeDataDir() async {
  final dir = Directory(dataDir);
  final candidatesDir = Directory(path.join(dataDir, 'candidates'));
  final questionsDir = Directory(path.join(dataDir, 'questions'));

  final isEmpty = !await dir.exists() ||
      (await dir.list().isEmpty);

  if (isEmpty) {
    // ignore: avoid_print
    print('Initializing data directory with seed data...');

    await dir.create(recursive: true);
    await candidatesDir.create(recursive: true);
    await questionsDir.create(recursive: true);

    await _copyDirectory(Directory(seedDataDir), dir);

    // ignore: avoid_print
    print('Initialized data directory with seed data at $dataDir');
  }
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  if (!await source.exists()) {
    // ignore: avoid_print
    print('Warning: Seed data directory not found at ${source.path}');
    return;
  }

  await for (final entity in source.list(recursive: false)) {
    final newPath = path.join(destination.path, path.basename(entity.path));
    if (entity is File) {
      await entity.copy(newPath);
    } else if (entity is Directory) {
      final newDir = Directory(newPath);
      await newDir.create(recursive: true);
      await _copyDirectory(entity, newDir);
    }
  }
}

Future<Response> _getCandidates(Request request) async {
  try {
    final candidatesDir = Directory(path.join(dataDir, 'candidates'));
    if (!await candidatesDir.exists()) {
      return Response.ok(jsonEncode({'candidates': []}),
          headers: {'Content-Type': 'application/json'});
    }

    final candidates = <Map<String, dynamic>>[];
    await for (final entity in candidatesDir.list()) {
      if (entity is Directory) {
        final candidateFile = File(path.join(entity.path, 'candidate.json'));
        if (await candidateFile.exists()) {
          final data = jsonDecode(await candidateFile.readAsString());
          final candidate = data['candidate'] ?? data;

          String? screeningGrade;
          double? technicalScore;
          double? assignmentScore;

          final screeningFile = File(path.join(entity.path, 'screening.json'));
          if (await screeningFile.exists()) {
            final screeningData = jsonDecode(await screeningFile.readAsString());
            screeningGrade = screeningData['grade'];
          } else if (data['screening'] != null) {
            screeningGrade = data['screening']['grade'];
          }

          String? technicalRecommendation;
          final technicalFile = File(path.join(entity.path, 'technical.json'));
          if (await technicalFile.exists()) {
            final techData = jsonDecode(await technicalFile.readAsString());
            technicalScore = _calculateTechnicalScore(techData);
            technicalRecommendation = techData['recommendation'];
          } else if (data['technical'] != null) {
            technicalScore = _calculateTechnicalScore(data['technical']);
            technicalRecommendation = data['technical']['recommendation'];
          }

          final assignmentFile = File(path.join(entity.path, 'assignment.json'));
          if (await assignmentFile.exists()) {
            final assignData = jsonDecode(await assignmentFile.readAsString());
            assignmentScore = _calculateAssignmentScore(assignData);
          } else if (data['assignment'] != null) {
            assignmentScore = _calculateAssignmentScore(data['assignment']);
          }

          candidates.add({
            ...candidate,
            'screeningGrade': screeningGrade,
            'technicalScore': technicalScore,
            'technicalRecommendation': technicalRecommendation,
            'assignmentScore': assignmentScore,
          });
        }
      }
    }

    return Response.ok(jsonEncode({'candidates': candidates}),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to get candidates: $e', 500);
  }
}

double? _calculateTechnicalScore(Map<String, dynamic>? data) {
  if (data == null) return null;
  final questions = data['questions'] as List<dynamic>?;
  if (questions == null || questions.isEmpty) return null;

  final scores = questions
      .where((q) => q['score'] != null && q['score'] > 0)
      .map<double>((q) => (q['score'] as num).toDouble())
      .toList();

  if (scores.isEmpty) return null;
  return scores.reduce((a, b) => a + b) / scores.length;
}

double? _calculateAssignmentScore(Map<String, dynamic>? data) {
  if (data == null) return null;
  final areaScores = data['areaScores'] as Map<String, dynamic>?;
  if (areaScores == null || areaScores.isEmpty) return null;

  double total = 0;
  double weightSum = 0;

  for (final entry in areaScores.values) {
    final score = entry['score'];
    final weight = entry['weight'];
    if (score != null && weight != null) {
      total += (score as num).toDouble() * ((weight as num).toDouble() / 100);
      weightSum += (weight).toDouble() / 100;
    }
  }

  return weightSum > 0 ? total / weightSum : null;
}

Future<Response> _getCandidate(Request request, String id) async {
  try {
    final candidateDir = Directory(path.join(dataDir, 'candidates', id));
    if (!await candidateDir.exists()) {
      return _errorResponse('Candidate not found', 404);
    }

    final candidateFile = File(path.join(candidateDir.path, 'candidate.json'));
    if (!await candidateFile.exists()) {
      return _errorResponse('Candidate not found', 404);
    }

    final data = jsonDecode(await candidateFile.readAsString());
    final result = <String, dynamic>{
      'candidate': data['candidate'] ?? data,
    };

    final screeningFile = File(path.join(candidateDir.path, 'screening.json'));
    if (await screeningFile.exists()) {
      result['screening'] = jsonDecode(await screeningFile.readAsString());
    } else if (data['screening'] != null) {
      result['screening'] = data['screening'];
    } else {
      result['screening'] = null;
    }

    final technicalFile = File(path.join(candidateDir.path, 'technical.json'));
    if (await technicalFile.exists()) {
      result['technical'] = jsonDecode(await technicalFile.readAsString());
    } else if (data['technical'] != null) {
      result['technical'] = data['technical'];
    } else {
      result['technical'] = null;
    }

    final assignmentFile = File(path.join(candidateDir.path, 'assignment.json'));
    if (await assignmentFile.exists()) {
      result['assignment'] = jsonDecode(await assignmentFile.readAsString());
    } else if (data['assignment'] != null) {
      result['assignment'] = data['assignment'];
    } else {
      result['assignment'] = null;
    }

    return Response.ok(jsonEncode(result),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to get candidate: $e', 500);
  }
}

Future<Response> _createCandidate(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    final name = body['name'] as String?;
    final email = body['email'] as String?;

    if (name == null || email == null) {
      return _errorResponse('Name and email are required', 400);
    }

    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final nameSlug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final id = 'c_${dateStr}_$nameSlug';

    final candidateDir = Directory(path.join(dataDir, 'candidates', id));
    await candidateDir.create(recursive: true);

    final candidate = {
      'id': id,
      'name': name,
      'email': email,
      'phone': body['phone'],
      'resumePath': null,
      'status': 'new',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'rejectionReason': null,
      'timeline': [],
    };

    final candidateFile = File(path.join(candidateDir.path, 'candidate.json'));
    await candidateFile.writeAsString(jsonEncode({'candidate': candidate}));

    return Response(201, body: jsonEncode(candidate),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to create candidate: $e', 500);
  }
}

Future<Response> _updateCandidate(Request request, String id) async {
  try {
    final candidateDir = Directory(path.join(dataDir, 'candidates', id));
    final candidateFile = File(path.join(candidateDir.path, 'candidate.json'));

    if (!await candidateFile.exists()) {
      return _errorResponse('Candidate not found', 404);
    }

    final existingData = jsonDecode(await candidateFile.readAsString());
    final existing = existingData['candidate'] ?? existingData;
    final updates = jsonDecode(await request.readAsString());

    final oldStatus = existing['status'];
    final newStatus = updates['status'] ?? oldStatus;

    if (oldStatus != newStatus) {
      final timeline = List<Map<String, dynamic>>.from(existing['timeline'] ?? []);
      timeline.add({
        'from': oldStatus,
        'to': newStatus,
        'at': DateTime.now().toIso8601String(),
        'note': updates['statusNote'] ?? 'Status changed',
      });
      existing['timeline'] = timeline;
    }

    updates.remove('statusNote');
    existing.addAll(updates);
    existing['updatedAt'] = DateTime.now().toIso8601String();

    await candidateFile.writeAsString(jsonEncode({'candidate': existing}));

    return Response.ok(jsonEncode(existing),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to update candidate: $e', 500);
  }
}

Future<Response> _deleteCandidate(Request request, String id) async {
  try {
    final candidateDir = Directory(path.join(dataDir, 'candidates', id));
    if (await candidateDir.exists()) {
      await candidateDir.delete(recursive: true);
    }
    return Response(204);
  } catch (e) {
    return _errorResponse('Failed to delete candidate: $e', 500);
  }
}

Future<Response> _getScreening(Request request, String id) async {
  try {
    final screeningFile = File(path.join(dataDir, 'candidates', id, 'screening.json'));
    if (await screeningFile.exists()) {
      final data = jsonDecode(await screeningFile.readAsString());
      return Response.ok(jsonEncode({'screening': data}),
          headers: {'Content-Type': 'application/json'});
    }

    final candidateFile = File(path.join(dataDir, 'candidates', id, 'candidate.json'));
    if (await candidateFile.exists()) {
      final data = jsonDecode(await candidateFile.readAsString());
      if (data['screening'] != null) {
        return Response.ok(jsonEncode({'screening': data['screening']}),
            headers: {'Content-Type': 'application/json'});
      }
    }

    return Response.ok(jsonEncode({'screening': null}),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to get screening: $e', 500);
  }
}

Future<Response> _saveScreening(Request request, String id) async {
  try {
    final updates = jsonDecode(await request.readAsString());
    final screeningFile = File(path.join(dataDir, 'candidates', id, 'screening.json'));

    Map<String, dynamic> existing = {};
    if (await screeningFile.exists()) {
      existing = jsonDecode(await screeningFile.readAsString());
    }

    _deepMerge(existing, updates);
    await screeningFile.writeAsString(jsonEncode(existing));

    await _touchCandidate(id);

    return Response.ok(jsonEncode(existing),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to save screening: $e', 500);
  }
}

Future<Response> _getTechnical(Request request, String id) async {
  try {
    final technicalFile = File(path.join(dataDir, 'candidates', id, 'technical.json'));
    if (await technicalFile.exists()) {
      final data = jsonDecode(await technicalFile.readAsString());
      return Response.ok(jsonEncode({'technical': data}),
          headers: {'Content-Type': 'application/json'});
    }

    final candidateFile = File(path.join(dataDir, 'candidates', id, 'candidate.json'));
    if (await candidateFile.exists()) {
      final data = jsonDecode(await candidateFile.readAsString());
      if (data['technical'] != null) {
        return Response.ok(jsonEncode({'technical': data['technical']}),
            headers: {'Content-Type': 'application/json'});
      }
    }

    return Response.ok(jsonEncode({'technical': null}),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to get technical: $e', 500);
  }
}

Future<Response> _saveTechnical(Request request, String id) async {
  try {
    final updates = jsonDecode(await request.readAsString());
    final technicalFile = File(path.join(dataDir, 'candidates', id, 'technical.json'));

    Map<String, dynamic> existing = {};
    if (await technicalFile.exists()) {
      existing = jsonDecode(await technicalFile.readAsString());
    }

    _deepMerge(existing, updates);
    await technicalFile.writeAsString(jsonEncode(existing));

    await _touchCandidate(id);

    return Response.ok(jsonEncode(existing),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to save technical: $e', 500);
  }
}

Future<Response> _getAssignment(Request request, String id) async {
  try {
    final assignmentFile = File(path.join(dataDir, 'candidates', id, 'assignment.json'));
    if (await assignmentFile.exists()) {
      final data = jsonDecode(await assignmentFile.readAsString());
      return Response.ok(jsonEncode({'assignment': data}),
          headers: {'Content-Type': 'application/json'});
    }

    final candidateFile = File(path.join(dataDir, 'candidates', id, 'candidate.json'));
    if (await candidateFile.exists()) {
      final data = jsonDecode(await candidateFile.readAsString());
      if (data['assignment'] != null) {
        return Response.ok(jsonEncode({'assignment': data['assignment']}),
            headers: {'Content-Type': 'application/json'});
      }
    }

    return Response.ok(jsonEncode({'assignment': null}),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to get assignment: $e', 500);
  }
}

Future<Response> _saveAssignment(Request request, String id) async {
  try {
    final updates = jsonDecode(await request.readAsString());
    final assignmentFile = File(path.join(dataDir, 'candidates', id, 'assignment.json'));

    Map<String, dynamic> existing = {};
    if (await assignmentFile.exists()) {
      existing = jsonDecode(await assignmentFile.readAsString());
    }

    _deepMerge(existing, updates);
    await assignmentFile.writeAsString(jsonEncode(existing));

    await _touchCandidate(id);

    return Response.ok(jsonEncode(existing),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to save assignment: $e', 500);
  }
}

Future<Response> _getQuestions(Request request, String bank) async {
  try {
    final questionsFile = File(path.join(dataDir, 'questions', '$bank.json'));
    if (!await questionsFile.exists()) {
      return _errorResponse('Question bank not found', 404);
    }

    final data = jsonDecode(await questionsFile.readAsString());
    return Response.ok(jsonEncode(data),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to get questions: $e', 500);
  }
}

Future<Response> _uploadResume(Request request, String id) async {
  try {
    final candidateDir = Directory(path.join(dataDir, 'candidates', id));
    if (!await candidateDir.exists()) {
      return _errorResponse('Candidate not found', 404);
    }

    final bytes = await request.read().expand((x) => x).toList();
    final resumePath = path.join(candidateDir.path, 'resume.pdf');
    await File(resumePath).writeAsBytes(bytes);

    final relativePath = 'candidates/$id/resume.pdf';

    final candidateFile = File(path.join(candidateDir.path, 'candidate.json'));
    if (await candidateFile.exists()) {
      final data = jsonDecode(await candidateFile.readAsString());
      final candidate = data['candidate'] ?? data;
      candidate['resumePath'] = relativePath;
      candidate['updatedAt'] = DateTime.now().toIso8601String();
      await candidateFile.writeAsString(jsonEncode({'candidate': candidate}));
    }

    return Response.ok(jsonEncode({'path': relativePath}),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to upload resume: $e', 500);
  }
}

Future<Response> _extractResumeInfo(Request request, String id) async {
  try {
    final candidateDir = Directory(path.join(dataDir, 'candidates', id));
    final resumeFile = File(path.join(candidateDir.path, 'resume.pdf'));

    if (!await resumeFile.exists()) {
      return _errorResponse('Resume not found', 404);
    }

    final contactInfo = await ResumeParser.extractContactInfo(resumeFile);
    return Response.ok(
      jsonEncode(contactInfo),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return _errorResponse('Failed to parse resume: $e', 500);
  }
}

Future<Response> _serveFile(Request request, String filePath) async {
  try {
    final resolvedPath = path.normalize(path.join(dataDir, filePath));
    final normalizedDataDir = path.normalize(dataDir);

    if (!resolvedPath.startsWith(normalizedDataDir)) {
      return Response.forbidden('Invalid path');
    }

    final file = File(resolvedPath);
    if (!await file.exists()) {
      return _errorResponse('File not found', 404);
    }

    final mimeType = lookupMimeType(resolvedPath) ?? 'application/octet-stream';
    final bytes = await file.readAsBytes();

    return Response.ok(bytes, headers: {
      'Content-Type': mimeType,
      'Content-Disposition': 'inline',
    });
  } catch (e) {
    return _errorResponse('Failed to serve file: $e', 500);
  }
}

Future<Response> _getConfig(Request request) async {
  try {
    final configFile = File(path.join(dataDir, 'config.json'));
    if (await configFile.exists()) {
      final data = jsonDecode(await configFile.readAsString());
      return Response.ok(jsonEncode(data),
          headers: {'Content-Type': 'application/json'});
    }

    final defaultConfig = {
      'interviewerName': 'Your Name',
      'companyName': 'Acrophase',
      'roleName': 'Python Backend Engineer',
    };
    return Response.ok(jsonEncode(defaultConfig),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to get config: $e', 500);
  }
}

Future<Response> _saveConfig(Request request) async {
  try {
    final updates = jsonDecode(await request.readAsString());
    final configFile = File(path.join(dataDir, 'config.json'));

    Map<String, dynamic> existing = {};
    if (await configFile.exists()) {
      existing = jsonDecode(await configFile.readAsString());
    }

    existing.addAll(updates);
    await configFile.writeAsString(jsonEncode(existing));

    return Response.ok(jsonEncode(existing),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return _errorResponse('Failed to save config: $e', 500);
  }
}

Future<void> _touchCandidate(String id) async {
  final candidateFile = File(path.join(dataDir, 'candidates', id, 'candidate.json'));
  if (await candidateFile.exists()) {
    final data = jsonDecode(await candidateFile.readAsString());
    final candidate = data['candidate'] ?? data;
    candidate['updatedAt'] = DateTime.now().toIso8601String();
    await candidateFile.writeAsString(jsonEncode({'candidate': candidate}));
  }
}

void _deepMerge(Map<String, dynamic> target, Map<String, dynamic> source) {
  source.forEach((key, value) {
    if (value is Map<String, dynamic> && target[key] is Map<String, dynamic>) {
      _deepMerge(target[key] as Map<String, dynamic>, value);
    } else if (key == 'timeline' && value is List && target[key] is List) {
      (target[key] as List).addAll(value);
    } else {
      target[key] = value;
    }
  });
}

Response _errorResponse(String message, int statusCode) {
  return Response(statusCode,
      body: jsonEncode({
        'error': message,
        'code': statusCode == 404 ? 'NOT_FOUND' : 'ERROR',
      }),
      headers: {'Content-Type': 'application/json'});
}
