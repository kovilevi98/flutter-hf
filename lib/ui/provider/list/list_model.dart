import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_homework/network/user_item.dart';
import 'package:get_it/get_it.dart';

class ListException extends Equatable implements Exception {
  final String message;

  const ListException(this.message);

  @override
  List<Object?> get props => [message];
}

class ListModel extends ChangeNotifier{
  var isLoading = false;
  var users = <UserItem>[];
  String? token;

  Future loadUsers() async {
    if(isLoading) return;
    try{
      changeLoading(true);
      var _dio = GetIt.I<Dio>();
      _dio.options.headers['Authorization'] = 'Bearer ${token ?? ""}';
      Response response = await _dio.get("/users");
      var data = response.data; //as List<Map<String, String>>;
      data.forEach((element) {
        users.add(UserItem(element["name"]!, element["avatarUrl"]!));
      });
      changeLoading(false);
    }on DioError catch(e){
      print(e);
      changeLoading(false);
      throw ListException(e.response!.data["message"]);
    }
  }

  changeLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

}