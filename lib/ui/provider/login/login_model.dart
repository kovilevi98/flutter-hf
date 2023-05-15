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
    if(isLoading) return;
    changeLoading(true);
      try{
        final Map<String, String> data = {
          "email": email,
          "password": password,
        };
        var _dio = GetIt.I<Dio>();
        Response response = await _dio.post("/login",
          data: data,
        );

        GetIt.I<Dio>().options.headers['authorization'] = 'Bearer ${response.data['token'] ?? ""}';
        if(response.data != null){
          if(rememberMe){
            GetIt.I<SharedPreferences>().setString("token", response.data['token']);
          }
          changeLoading(false);
          return response.data['token'];
        }

      }on DioError catch(e){
        changeLoading(false);
        throw LoginException(e.response!.data["message"]);
      }
    changeLoading(false);
  }

  changeLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  bool tryAutoLogin() {
    if(isLoading) return false;

    isLoading = true;
    var token = GetIt.I<SharedPreferences>().getString("token");
    if(token == null || token == ""){
      isLoading = false;
      return false;
    }

      isLoading = false;
      return true;
  }
}