import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_homework/ui/provider/list/list_model.dart';
import 'package:flutter_homework/ui/provider/list/list_page.dart';
import 'package:flutter_homework/ui/provider/login/login_model.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validators/validators.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onPageInitialization();
    });
  }

  _onPageInitialization() async {
    var result = Provider.of<LoginModel>(context, listen: false).tryAutoLogin();
    if (result) {
      var token = GetIt.I<SharedPreferences>().getString("token");
      Provider.of<ListModel>(context, listen: false).token = token!;
      //Navigator.pushReplacementNamed(context, '/list');
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => ListPageProvider()));
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
              Text("Login",
                  style: Theme.of(context)
                      .textTheme
                      .headline2
                      ?.copyWith(color: Colors.black)),
              SizedBox(
                height: 15,
              ),
              TextField(
                textAlignVertical: TextAlignVertical.center,
                controller: emailCtrl,
                enabled: !Provider.of<LoginModel>(context).isLoading,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                onChanged: (s) {
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
              TextField(
                textAlignVertical: TextAlignVertical.center,
                controller: passwordCtrl,
                enabled: !Provider.of<LoginModel>(context).isLoading,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                onChanged: (s) {
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
                      onChanged: Provider.of<LoginModel>(context).isLoading
                          ? (s) {}
                          : (newValue) {
                              setState(() {
                                checkedValue = !checkedValue;
                              });
                            },
                      value: checkedValue),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text("Remember me",
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
                        onPressed: Provider.of<LoginModel>(context).isLoading
                            ? () {}
                            : () async {
                                bool valid = true;
                                if (!validateEmail(emailCtrl.text)) {
                                  setState(() {
                                    emailError = "The Email address is invalid";
                                  });
                                  valid = false;
                                }
                                if (!validatePass(passwordCtrl.text)) {
                                  setState(() {
                                    passError =
                                        "The Password is not strong enough";
                                  });
                                  valid = false;
                                }

                                FocusScope.of(context).unfocus();
                                if (valid) {
                                  try {
                                    var token = await Provider.of<LoginModel>(
                                            context,
                                            listen: false)
                                        .login(emailCtrl.text,
                                            passwordCtrl.text, checkedValue);
                                    if (token != null && token != '') {
                                      //Provider.of<Data>(context, listen: false).changeToken(token);
                                      Provider.of<ListModel>(context,
                                              listen: false)
                                          .token = token;
                                    }
                                    //Navigator.pushReplacementNamed(context, '/list');
                                    // ignore: use_build_context_synchronously
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                ChangeNotifierProvider(
                                                    create: (context) => ListModel(),
                                                    child:
                                                        ListPageProvider())));
                                  } on LoginException catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.message)));
                                  }
                                }
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

  bool validateEmail(String email) {
    print(email);
    return isEmail(email);
  }

  bool validatePass(String pass) {
    return pass.length >= 6;
  }
}
