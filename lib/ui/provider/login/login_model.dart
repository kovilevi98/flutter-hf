import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_homework/ui/provider/data/data.dart';
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
    isLoading = true;
      try{
        final Map<String, String> data = {
          "email": email,
          "password": password,
        };
        var _dio = GetIt.I<Dio>();
        Response response = await _dio.post("/login",
          data: data,
        );

        if(response.data != null){
          Data().token = response.data['token'];
          if(rememberMe){
            GetIt.I<SharedPreferences>().setString("token", response.data['token']);
            GetIt.I<SharedPreferences>().setString("email", email);
            GetIt.I<SharedPreferences>().setString("password", password);
          }
          isLoading = false;
          return response.data['token'];
        }

      }on DioError catch(e){
        //print(e);
        isLoading = false;
        throw LoginException(e.response!.data["message"]);
      }

  }

  bool validateEmail(String email){
    return isEmail(email);
  }

  bool validatePass(String pass){
    return pass.length >= 6;
  }

  bool tryAutoLogin() {
    isLoading = true;
    var token = GetIt.I<SharedPreferences>().getString("token");
    var email = GetIt.I<SharedPreferences>().getString("email");
    var password = GetIt.I<SharedPreferences>().getString("password");
    if(token == null || token == ""){
      isLoading = false;
      return false;
    }

    if(email == null || email == ""){
      isLoading = false;
      return false;
    }

    if(password == null || password == ""){
      isLoading = false;
      return false;
    }
      Data().token = token;
      isLoading = false;
      return true;
  }
}