import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:authpass/env/_base.dart';
import 'package:kdbx/kdbx.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PathUtils {
  factory PathUtils() => _instance;

  PathUtils._();

  static final PathUtils _instance = PathUtils._();
  static final Completer<bool> runAppFinished = Completer<bool>();
  static Future<bool> get waitForRunAppFinished => runAppFinished.future;

  Future<Directory> getAppDataDirectory() async {
    if (Platform.isIOS || Platform.isMacOS) {
      return _namespaced(await getApplicationSupportDirectory());
    }
    if (Platform.isAndroid) {
      return _namespaced(await getApplicationDocumentsDirectory());
    }
    return _namespaced(await _getDesktopDirectory());
  }

  Directory _namespaced(Directory base) {
    final namespace = Env.value?.storageNamespace;
    if (namespace == null) {
      return base;
    }
    return Directory(path.join(base.path, namespace));
  }

  Future<Directory> getLogDirectory() async {
    return Directory(
        path.join((_namespaced(await getTemporaryDirectory())).path, 'logs'));
  }

  Future<Directory> _getDesktopDirectory() async {
    // https://stackoverflow.com/a/32937974/109219
    final userHome =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    final dataDir = Directory(path.join(userHome, '.authpass', 'data'));
    await dataDir.create(recursive: true);
    return dataDir;
  }

  Future<File> saveToTempDirectory(Uint8List bytes,
      {@required String dirPrefix, @required String fileName}) async {
    assert(fileName != null);
    final tempDirectory = await getTemporaryDirectory();
    final dir = await tempDirectory.createTemp();
    final f = File(path.join(dir.path, fileName));
    await f.writeAsBytes(bytes);
    return f;
  }
}
