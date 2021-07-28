/*
 * Copyright 2019 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogManager {
  late DateTime date;
  late String logName;
  // File file;

  LogManager() {
    date = DateTime.now();
    logName = 'movisens_log_$date.txt';
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$logName');
  }

  Future<File> writeLog(String event) async {
    final file = await _localFile;
    return file.writeAsString('$event\n', mode: FileMode.append);
  }

  Future<String> readLog() async {
    final file = await _localFile;
    return await file.readAsString();
  }
}
