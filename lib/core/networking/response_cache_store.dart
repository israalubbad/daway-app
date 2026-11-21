import 'dart:convert';
import 'dart:io';

/// One stored answer: the decoded JSON body and when it was kept.
class CachedResponse {
  final Object? body;
  final DateTime storedAt;

  const CachedResponse({required this.body, required this.storedAt});
}

/// Where [ResponseCacheInterceptor] keeps answers between launches.
abstract interface class ResponseCacheStore {
  Future<CachedResponse?> read(String key);

  Future<void> write(String key, CachedResponse response);

  /// Forgets everything — the session ended, and what was kept belongs to it.
  Future<void> clear();
}

/// A few small JSON files in the system's temporary directory. Bounded twice —
/// by [maxEntries] and by [maxBytes] — and the oldest go first, so the cache
/// never grows past a couple of megabytes (the OS may empty the directory
/// whenever it needs the room, which only costs one request).
class FileResponseCacheStore implements ResponseCacheStore {
  final Future<Directory> Function() _directory;
  final int maxEntries;
  final int maxBytes;

  FileResponseCacheStore(
    this._directory, {
    this.maxEntries = 40,
    this.maxBytes = 2 * 1024 * 1024,
  });

  Future<Directory> _dir() async {
    final dir = Directory('${(await _directory()).path}${Platform.pathSeparator}api_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(String key) async {
    final dir = await _dir();
    return File('${dir.path}${Platform.pathSeparator}${fnv1a64(key)}.json');
  }

  @override
  Future<CachedResponse?> read(String key) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return null;
      final storedAt = DateTime.tryParse('${json['storedAt']}');
      if (storedAt == null) return null;
      return CachedResponse(body: json['body'], storedAt: storedAt);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, CachedResponse response) async {
    try {
      final file = await _file(key);
      await file.writeAsString(
        jsonEncode({'storedAt': response.storedAt.toIso8601String(), 'body': response.body}),
        flush: true,
      );
      await _trim();
    } catch (_) {
      // A cache that cannot write is just a cache that stays empty.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final dir = await _dir();
      await for (final entity in dir.list()) {
        if (entity is File) await entity.delete();
      }
    } catch (_) {}
  }

  /// Deletes the oldest files until both limits hold.
  Future<void> _trim() async {
    final dir = await _dir();
    final files = <({File file, DateTime modified, int size})>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      files.add((file: entity, modified: stat.modified, size: stat.size));
    }
    files.sort((a, b) => a.modified.compareTo(b.modified));
    var total = files.fold<int>(0, (sum, f) => sum + f.size);
    var count = files.length;
    for (final f in files) {
      if (count <= maxEntries && total <= maxBytes) break;
      await f.file.delete();
      total -= f.size;
      count--;
    }
  }
}

/// A short, stable name for [input] (FNV-1a, 64 bits) — the file name of a key.
String fnv1a64(String input) {
  var hash = 0xcbf29ce484222325;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash *= 0x100000001b3;
  }
  return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}
