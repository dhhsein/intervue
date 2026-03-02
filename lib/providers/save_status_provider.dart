import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SaveStatus {
  idle,
  saving,
  saved,
  error,
  offline,
}

class SaveStatusNotifier extends Notifier<SaveStatus> {
  @override
  SaveStatus build() => SaveStatus.idle;

  void setSaving() {
    state = SaveStatus.saving;
  }

  void setSaved() {
    state = SaveStatus.saved;
    Future.delayed(const Duration(seconds: 3), () {
      if (state == SaveStatus.saved) {
        state = SaveStatus.idle;
      }
    });
  }

  void setError() {
    state = SaveStatus.error;
  }

  void setOffline() {
    state = SaveStatus.offline;
  }
}

final saveStatusProvider = NotifierProvider<SaveStatusNotifier, SaveStatus>(
  SaveStatusNotifier.new,
);
