import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// The state app 1.4.0 kept between launches (`snapshot_v1.json`). Since the
/// copy on the phone (offline sync, chantier 10), it is only read, on the
/// first launch after the update and until the full copy arrives (H15), then
/// erased. Nothing writes it any more.
///
/// Abstracted so `SyncService` can be unit tested with an in-memory store.
abstract class SnapshotStore {
  Future<String?> read();
  Future<void> delete();
}

/// `<application support dir>/snapshot_v1.json`. Every failure is swallowed:
/// the snapshot only bridges the first launch after the update, and the full
/// copy that follows makes the app correct either way.
class FileSnapshotStore implements SnapshotStore {
  static const _fileName = 'snapshot_v1.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<String?> read() async {
    try {
      final f = await _file();
      return await f.exists() ? await f.readAsString() : null;
    } catch (e) {
      debugPrint('Snapshot read failed: $e');
      return null;
    }
  }

  @override
  Future<void> delete() async {
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('Snapshot delete failed: $e');
    }
  }
}
