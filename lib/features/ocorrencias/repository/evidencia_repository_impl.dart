import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../model/evidencia_metadata.dart';
import '../model/evidencia_response.dart';
import 'evidencia_repository.dart';

final evidenciaRepositoryProvider = Provider<EvidenciaRepository>((ref) {
  return EvidenciaRepositoryImpl(dio: ref.watch(dioProvider));
});

class EvidenciaRepositoryImpl implements EvidenciaRepository {
  final Dio dio;

  EvidenciaRepositoryImpl({required this.dio});

  @override
  Future<EvidenciaResponse> uploadParaNc(
    String ncId,
    File foto,
    EvidenciaMetadata meta, {
    String tipo = 'OCORRENCIA',
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(foto.path),
      'tipo': tipo,
      'latitude': meta.latitude.toString(),
      'longitude': meta.longitude.toString(),
      'capturedAt': meta.capturedAt.toString(),
      'origem': 'MOBILE',
      if (meta.cidade != null) 'cidade': meta.cidade,
    });
    final response = await dio.post<Map<String, dynamic>>(
      '/api/evidencias/nao-conformidade/$ncId',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    return EvidenciaResponse.fromJson(response.data!);
  }

  @override
  Future<EvidenciaResponse> uploadParaDesvio(
    String desvioId,
    File foto,
    EvidenciaMetadata meta, {
    String tipo = 'OCORRENCIA',
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(foto.path),
      'tipo': tipo,
      'latitude': meta.latitude.toString(),
      'longitude': meta.longitude.toString(),
      'capturedAt': meta.capturedAt.toString(),
      'origem': 'MOBILE',
      if (meta.cidade != null) 'cidade': meta.cidade,
    });
    final response = await dio.post<Map<String, dynamic>>(
      '/api/evidencias/desvio/$desvioId',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    return EvidenciaResponse.fromJson(response.data!);
  }
}
