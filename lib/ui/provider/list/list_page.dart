import 'package:flutter/material.dart';
import 'package:flutter_homework/ui/provider/data/data.dart';
import 'package:flutter_homework/ui/provider/list/list_model.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListPageProvider extends StatefulWidget {
  const ListPageProvider({Key? key}) : super(key: key);

  @override
  State<ListPageProvider> createState() => _ListPageProviderState();
}

class _ListPageProviderState extends State<ListPageProvider> {
  var model = ListModel();

  @override
  void initState() {
    _onPageInitialization();
    super.initState();
  }

  _onPageInitialization() async {
    setState(() {
      model.isLoading = true;
    });

    try{
      //model.token = GetIt.I<SharedPreferences>().getString("token")!;
      var token;
      if(Data().token != null){
        model.token = Data().token!;////
      } else {
        //GetIt.I<SharedPreferences>().getString("token")!;//"ACCESS_TOKEN";
      }
      var result = await model.loadUsers();
    }  on ListException catch(e){
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(e.message)));
    }

    setState(() {
      model.isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista"),
        leading: IconButton( 
          onPressed: (){
            GetIt.I<SharedPreferences>().clear();
            Navigator.pushReplacementNamed(context, '/');
          }, icon: Icon(Icons.arrow_back, color: Colors.white,),),
      ),
      body: (model.isLoading) ? Center(child: const CircularProgressIndicator()) :SingleChildScrollView(
        child: Column(
          children: [
            ...List.generate(
              model.users.length,
                  (index) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      child:
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30.0,
                            backgroundImage:
                            NetworkImage(model.users[index].avatarUrl),
                            backgroundColor: Colors.transparent,
                          ),
                          SizedBox(width: 15,),
                          Text(model.users[index].name),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
