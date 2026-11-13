import 'dart:io';

import 'package:dio/dio.dart';

import '../data/app_database.dart';
import 'token_store.dart';

const defaultServerUrl = 'http://10.0.2.2:8000';

Map<String, String> _hostHeadersFor(String baseUrl) {
  if (Uri.tryParse(baseUrl)?.host == '10.0.2.2') {
    return {HttpHeaders.hostHeader: 'localhost'};
  }
  return const {};
}

class ApiClient {
  ApiClient(this._tokens) {
    dio = Dio(BaseOptions(
      baseUrl: defaultServerUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 25),
      headers: {
        'Accept': 'application/json',
        ..._hostHeadersFor(defaultServerUrl),
      },
    ));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final access = await _tokens.access;
          if (access != null && access.isNotEmpty) {
            options.headers[HttpHeaders.authorizationHeader] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode != 401 ||
              request.extra['retried'] == true ||
              request.path.contains('/api/auth/token/')) {
            handler.next(error);
            return;
          }
          final refresh = await _tokens.refresh;
          if (refresh == null) {
            handler.next(error);
            return;
          }
          try {
            final response = await Dio(
              BaseOptions(headers: _hostHeadersFor(dio.options.baseUrl)),
            ).post<Map<String, dynamic>>(
              '${dio.options.baseUrl}/api/auth/token/refresh/',
              data: {'refresh': refresh},
            );
            final access = response.data?['access']?.toString();
            if (access == null || access.isEmpty) {
              handler.next(error);
              return;
            }
            await _tokens.saveAccess(access);
            request
              ..headers[HttpHeaders.authorizationHeader] = 'Bearer $access'
              ..extra['retried'] = true;
            handler.resolve(await dio.fetch(request));
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }

  final TokenStore _tokens;
  late final Dio dio;

  String get serverUrl => dio.options.baseUrl;

  void setServerUrl(String value) {
    final serverUrl = value.trim().replaceFirst(RegExp(r'/+$'), '');
    dio.options.baseUrl = serverUrl;
    dio.options.headers.remove(HttpHeaders.hostHeader);
    dio.options.headers.addAll(_hostHeadersFor(serverUrl));
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/auth/token/',
      data: {'username': username, 'password': password},
    );
    final access = response.data?['access']?.toString();
    final refresh = response.data?['refresh']?.toString();
    if (access == null || refresh == null) {
      throw const FormatException('El servidor no devolvió tokens válidos.');
    }
    await _tokens.save(access: access, refresh: refresh);
    return response.data!;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await dio.get<Map<String, dynamic>>('/api/auth/me/');
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> catalogos() async {
    final response = await dio.get<Map<String, dynamic>>('/api/catalogos/');
    return response.data ?? const {};
  }

  Future<List<dynamic>> syncConsejos(List<Map<String, dynamic>> items) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/sync/consejos/',
      data: {'items': items},
    );
    return response.data?['resultados'] as List<dynamic>? ?? const [];
  }

  Future<void> uploadPhoto(FotoLocal photo, int consejoId) async {
    final form = FormData.fromMap({
      'uuid': photo.uuid,
      'descripcion': photo.descripcion,
      'imagen': await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split('/').last,
      ),
    });
    await dio.post<void>(
      '/api/consejos/$consejoId/fotos/',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
