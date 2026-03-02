import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/data_service.dart';
import '../services/local_data_service.dart';

final dataServiceProvider = Provider<DataService>((ref) {
  return LocalDataService();
});
