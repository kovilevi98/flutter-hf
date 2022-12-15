import 'package:flutter/material.dart';
import 'package:flutter_homework/ui/provider/list/list_model.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListPageProvider extends StatefulWidget {
  String token;
  ListPageProvider({Key? key, required this.token}) : super(key: key);

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
      var result = await model.loadUsers(widget.token);
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
        leading: BackButton(
        onPressed: (){
            var token = GetIt.I<SharedPreferences>().setString("token", "");
            Navigator.pushReplacementNamed(context, '/');
        },),
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
