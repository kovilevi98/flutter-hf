import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:username_gen/username_gen.dart';

class DataSourceInterceptor extends Interceptor {
  static const _accessToken = 'ACCESS_TOKEN';

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    await Future.delayed(
      const Duration(seconds: 1),
    );
    if (options.path.contains('login')) {
      var data = options.data;
      var email = data['email'] as String;
      var password = data['password'] as String;
      if (email == 'login@gmail.com' && password == 'password') {
        var response = Response(requestOptions: options, data: {
          'token': _accessToken,
        });
        handler.resolve(response, true);
      } else {
        var error = DioError(
          requestOptions: options,
          type: DioErrorType.response,
          response: Response(
            requestOptions: options,
            data: {
              'message': 'Wrong email or password!',
            },
          ),
        );
        handler.reject(error, true);
      }
    } else if (options.path.contains('users')) {
      var token = options.headers['Authorization'];
      if (token != 'Bearer $_accessToken') {
        handler.reject(
          DioError(
            requestOptions: options,
            type: DioErrorType.response,
            response: Response(requestOptions: options, data: {
              'message': 'Unauthorized user!',
            }),
          ),
          true,
        );
      } else {
        var generator = UsernameGen();
        handler.resolve(
          Response(
            requestOptions: options,
            data: [
              for (int i = 0; i < 40; i++)
                {
                  'name': generator.generate(),
                  'avatarUrl': 'https://placealpaca.com/${100 + i}/${100 + i}?',
                }
            ],
          ),
          true,
        );
      }
    }
  }
}
