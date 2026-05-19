import 'dart:io';

import '../model/evidencia_metadata.dart';
import '../model/evidencia_response.dart';

abstract class EvidenciaRepository {
  Future<EvidenciaResponse> uploadParaNc(
    String ncId,
    File foto,
    EvidenciaMetadata meta,
  );
  Future<EvidenciaResponse> uploadParaDesvio(
    String desvioId,
    File foto,
    EvidenciaMetadata meta,
  );
}
