import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/formatters.dart';

class ExportService {
  const ExportService();

  /// Writes [csv] to a temp file and opens the Android share sheet so it can
  /// be saved to Drive/Files, emailed or sent on WhatsApp.
  Future<void> shareCsv(String csv, {String prefix = 'hitzone'}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$prefix-${todayKey()}.csv');
    await file.writeAsString(csv, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'HITZONE export',
      ),
    );
  }
}
