import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:base_flutter_framework/utils/shared.dart';

import 'package:dio/dio.dart';

class ServiceCommon {
  static ServiceCommon? instance;
  final String configUrl = "http://192.168.1.112:8004/config";

  // final String modeArticle

  static ServiceCommon? getInstance() {
    if (instance == null) instance = new ServiceCommon();
    return instance;
  }

  Future<Response?> getHttp(
      {Map<String, dynamic>? param,
      required String api,
      required String host,
      bool? cancelRequest}) async {
    Dio dio = getApiClient();
    // await Dio(options)?.clear();
    jsonEncode(param);
    Response response = await dio.get(
      host + api,
      queryParameters: param,
    );
    return response;
  }

  Future<Response?> postHttp({
    Map<String, dynamic>? param,
    required String api,
    required String host,
  }) async {
    jsonEncode(param);
    Dio dio = getApiClient();
    Response response = await dio.post(host + api, data: param);
    print(response);
    return response;
  }

  Future<Response?> put({
    Map<String, dynamic>? param,
    required String api,
    required String host,
  }) async {
    Dio dio = getApiClient();
    ;
    Response response = await dio.put(host + api, data: param);
    return response;
  }

  Future<Response?> patch({
    Map<String, dynamic>? param,
    required String api,
    required String host,
  }) async {
    Dio dio = getApiClient();
    Response response = await dio.patch(host + api,
        // queryParameters: param,
        data: param);
    print(response);
    return response;
  }

  Future<Response?> deleteHttp(
      {Map<String, dynamic>? param,
      required String host,
      required String api}) async {
    Dio dio = getApiClient();
    Response response = await dio.delete(host + api, data: param);
    return response;
  }

  Future<Response?> patchHttp(
      {required Map<String, dynamic> param,
      required String host,
      required String api}) async {
    Dio dio = getApiClient();
    Response response = await dio.patch(host + api, data: param);
    return response;
  }

  // Future<Response?> upLoadImageFile({
  //   required Map<String, dynamic>? param,
  //   required File file,
  //   required String fileName,
  // }) async {
  //   ImageProperties properties =
  //       await FlutterNativeImage.getImageProperties(file.path);
  //   File compressedFile = await FlutterNativeImage.compressImage(file.path,
  //       quality: 90,
  //       targetWidth: 1200,
  //       targetHeight: (properties.height! * 1200 / properties.width!).round());

  //   FormData data = FormData.fromMap({
  //     "file":
  //         await MultipartFile.fromFile(compressedFile.path, filename: fileName),
  //   });

  //   Dio dio = getApiClient();
  //   Response response =
  //       await dio.post(hostImageUpload, queryParameters: param, data: data);

  //   return response;
  // }

  BaseOptions _baseOptionsFromToken() {
    return BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: Duration(seconds: 60), // 60 seconds
        receiveTimeout: Duration(seconds: 60), // 60 seconds
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        });
  }

  Dio getApiClient() {
    // Dio().close();
    Dio().close();
    Dio dio = new Dio(_baseOptionsFromToken());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          request.headers['Accept'] = "application/json";
          request.headers['Content-type'] = "application/json";
          ;
          return handler.next(request);
        },
        onError: (e, handler) async {},
      ),
    );

    return dio;
  }
}
