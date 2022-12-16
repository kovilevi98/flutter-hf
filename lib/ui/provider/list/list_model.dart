import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_homework/network/user_item.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListException extends Equatable implements Exception {
  final String message;

  const ListException(this.message);

  @override
  List<Object?> get props => [message];
}

class ListModel extends ChangeNotifier{
  var isLoading = false;
  var users = <UserItem>[];
  var token = "";

  Future loadUsers() async {
    try{
      isLoading = true;
      var _dio = GetIt.I<Dio>();
      _dio.options.headers['Authorization'] = 'Bearer ' + token;
      Response response = await _dio.get("/users");
      var data = response.data; //as List<Map<String, String>>;
      data.forEach((element) {
        users.add(UserItem(element["name"]!, element["avatarUrl"]!));
      });
      isLoading = false;
    }on DioError catch(e){
      print(e);
      isLoading = false;
      throw ListException(e.response!.data["message"]);
    }

  }
}