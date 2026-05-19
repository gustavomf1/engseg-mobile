import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus { idle, syncing, error }

final syncStatusProvider = StateProvider<SyncStatus>((_) => SyncStatus.idle);
