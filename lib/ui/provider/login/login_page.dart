import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_homework/ui/provider/login/login_model.dart';

class LoginPageProvider extends StatefulWidget {
  const LoginPageProvider({super.key});

  @override
  State<LoginPageProvider> createState() => _LoginPageProviderState();
}

class _LoginPageProviderState extends State<LoginPageProvider> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool checkedValue = false;
  String? emailError;
  String? passError;

  final model = LoginModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onPageInitialization();
    });

  }

  _onPageInitialization() async {
      var result = model.tryAutoLogin();
      if(result){
        Navigator.pushReplacementNamed(context, '/list');
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Login",
              style: Theme.of(context)
                  .textTheme
                  .headline2
                  ?.copyWith(color: Colors.black)),
              SizedBox(
                height: 15,
              ),
              TextFormField(
                textAlignVertical: TextAlignVertical.center,
                controller: emailCtrl,
                enabled: !model.isLoading,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                onChanged: (s){
                  setState(() {
                    emailError = null;
                  });
                },
                decoration: InputDecoration(
                    hintText: "Email",
                    filled: true,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    fillColor: Colors.white,
                    errorText: emailError,
                    contentPadding: const EdgeInsets.all(10)),
              ),
              SizedBox(
                height: 15,
              ),
              TextFormField(
                textAlignVertical: TextAlignVertical.center,
                controller: passwordCtrl,
                enabled: !model.isLoading,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                onChanged: (s){
                  setState(() {
                    passError = null;
                  });
                },
                decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    fillColor: Colors.white,
                    errorText: passError,
                    contentPadding: const EdgeInsets.all(10)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                      side: BorderSide(color: Colors.black),
                      onChanged: model.isLoading ? (s){} : (newValue) {
                        setState(() {
                          checkedValue = !checkedValue;
                        });
                      },
                      value: checkedValue),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                        "Remember me",
                        style: Theme.of(context)
                            .textTheme
                            .headline6
                            ?.copyWith(color: Colors.black)),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                        onPressed: model.isLoading ? (){} :  () async {
                          bool valid = true;
                          if (!model.validateEmail(emailCtrl.text)) {
                            setState(() {
                              emailError = "The Email address is invalid";
                            });
                            valid = false;
                          }
                          if (!model.validatePass(passwordCtrl.text)) {
                            setState(() {
                              passError = "The Password is not strong enough";
                            });
                            valid = false;
                          }

                          FocusScope.of(context).unfocus();
                          setState(() {
                           model.isLoading = true;
                          });
                          if(valid){
                           try{
                             var token = await model.login(emailCtrl.text, passwordCtrl.text, checkedValue);
                             Navigator.pushReplacementNamed(context, '/list');
                           } on LoginException catch(e){
                             ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(e.message)));
                           }
                          }
                          setState(() {
                            model.isLoading = false;
                          });
                        },
                        child: const Text("Login")),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
