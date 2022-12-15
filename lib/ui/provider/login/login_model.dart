import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validators/validators.dart';

class LoginException extends Equatable implements Exception{
  final String message;

  const LoginException(this.message);

  @override
  List<Object?> get props => [message];
}

class LoginModel extends ChangeNotifier{
  var isLoading = false;

  Future login(String email, String password, bool rememberMe) async {
      try{
        final Map<String, String> data = {
          "email": email,
          "password": password,
        };
        var _dio = GetIt.I<Dio>();
        Response response = await _dio.post("/login",
          data: data,
        );

        if(rememberMe){
          GetIt.I<SharedPreferences>().setString("token", response.data['token']);
        }
        return response.data['token'];
      }on DioError catch(e){
        print(e);
        throw LoginException(e.response!.data["message"]);
      }

  }

  bool validateEmail(String email){
    return isEmail(email);
  }

  bool validatePass(String pass){
    return pass.length >= 6;
  }

  Future<bool> tryAutoLogin() async {
    var token = GetIt.I<SharedPreferences>().getString("token");
    if(token == null || token == ""){
      return false;
    }
    try{
      final Map<String, String> data = {
        "token": token
      };
      var _dio = GetIt.I<Dio>();
      Response response = await _dio.post("/login",
        data: data,
      );
      return response.data["token"];
    }on DioError catch(e){
      return false;
      print(e);
      throw LoginException(e.response!.data["message"]);
    } catch(e){
      return false;
    }

  }
}