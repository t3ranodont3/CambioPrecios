import 'dart:io';
import 'package:flutter/foundation.dart'; // Add this line

void main() {
  final file = File(
    'D:/PROYECTOS/CambioPreciosDIGEMID/Manual de Usuario carga archivo excel4_3_2026.pdf',
  );
  final bytes = file.readAsBytesSync();
  final latin = String.fromCharCodes(bytes);

  // Extract crude strings over 10 chars
  final re = RegExp(r'[A-Za-z0-9\s_:*/-]{10,}');
  final matches = re.allMatches(latin);

  final out = File('pdf_strings.txt');
  for (var m in matches) {
    if (m.group(0)!.trim().length > 10) {
      out.writeAsStringSync('${m.group(0)!}\n', mode: FileMode.append);
    }
  }
  debugPrint('Done parsing crude strings');
}
