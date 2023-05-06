import 'package:flutter/material.dart';
import 'package:flutter_homework/ui/provider/list/list_model.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListPageProvider extends StatefulWidget {
  const ListPageProvider({Key? key}) : super(key: key);

  @override
  State<ListPageProvider> createState() => _ListPageProviderState();
}

class _ListPageProviderState extends State<ListPageProvider> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onPageInitialization();
    });
  }

  _onPageInitialization() async {
    try{
       var result = await Provider.of<ListModel>(context, listen: false).loadUsers();
    }  on ListException catch(e){
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(e.message)));
    }
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
      body: (Provider.of<ListModel>(context).isLoading) ? Center(child: const CircularProgressIndicator()) :SingleChildScrollView(
        child: Column(
          children: [
            ...List.generate(
              Provider.of<ListModel>(context).users.length,
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
                            NetworkImage(Provider.of<ListModel>(context).users[index].avatarUrl),
                            backgroundColor: Colors.transparent,
                          ),
                          SizedBox(width: 15,),
                          Text(Provider.of<ListModel>(context).users[index].name),
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
