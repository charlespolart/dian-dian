import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Where the last known bootstrap state is kept between launches.
///
/// Abstracted so `SyncService` can be unit tested with an in-memory store.
abstract class SnapshotStore {
  Future<String?> read();
  Future<void> write(String json);
  Future<void> delete();
}

/// `<application support dir>/snapshot_v1.json`. Every failure is swallowed:
/// the snapshot is a first-paint accelerator, never a source of truth, and
/// the network bootstrap that follows makes the app correct either way.
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
  Future<void> write(String json) async {
    try {
      final f = await _file();
      // Write-then-rename so a crash mid-write never leaves a torn file.
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(f.path);
    } catch (e) {
      debugPrint('Snapshot write failed: $e');
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
