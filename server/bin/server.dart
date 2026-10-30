import 'dart:io';

import 'package:shelf/shelf_io.dart' as io;
import 'package:sodiscan_server/api.dart';
import 'package:sodiscan_server/consumption_store.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final dataFile = File.fromUri(Platform.script.resolve('../data/consumptions.json'));
  final server = await io.serve(buildHandler(ConsumptionStore(dataFile)), InternetAddress.anyIPv4, port);
  stdout.writeln('SodiScan API berjalan di http://localhost:${server.port}');
  stdout.writeln('Data disimpan di ${dataFile.path}');
}
