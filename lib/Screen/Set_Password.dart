import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pinko_implex/Helper/String.dart';
import 'package:pinko_implex/Helper/cropped_container.dart';
import 'package:pinko_implex/Screen/Login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';

class SetPass extends StatefulWidget {
  final String mobileNumber;

  const SetPass({
    Key? key,
    required this.mobileNumber,
  })  : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<SetPass> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final confirmpassController = TextEditingController();
  final passwordController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  String? password, comfirmpass;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;

  AnimationController? buttonController;

  void validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  Future<void> checkNetwork() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      getResetPass();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
        await buttonController!.reverse();
      });
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior:  SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          right: 0,
          left: 0),
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      elevation: 1.0,
    ));
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.only(top: kToolbarHeight),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(const Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                          builder: (BuildContext context) => super.widget));
                } else {
                  await buttonController!.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  Future<void> getResetPass() async {
    try {
      var data = {MOBILENO: widget.mobileNumber, NEWPASS: password};
      Response response =
      await post(getResetPassApi, body: data, headers: headers)
          .timeout(const Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);
        bool error = getdata['error'];
        String? msg = getdata['message'];
        await buttonController!.reverse();
        if (!error) {
          setSnackbar(getTranslated(context, 'PASS_SUCCESS_MSG')!);
          Future.delayed(const Duration(seconds: 1)).then((_) {
            Navigator.of(context).pushReplacement(CupertinoPageRoute(
              builder: (BuildContext context) => const Login(),
            ));
          });
        } else {
          setSnackbar(msg!);
        }
      }
      if (mounted) setState(() {});
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!);
      await buttonController!.reverse();
    }
  }

  subLogo() {
    return Expanded(
      child: Center(
        child: Image.asset(
          'assets/images/homelogo.png',
        ),
      ),
    );
  }

  forgotpassTxt() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(
          top: 40.0,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            getTranslated(context, 'FORGOT_PASSWORDTITILE')!,
            style: Theme.of(context).textTheme.headline6!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,
                fontSize: 23,
                letterSpacing: 0.8),
          ),
        ));
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  setPass() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Container(
        height: 53,
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.lightWhite,
          borderRadius: BorderRadius.circular(10.0),
        ),
        alignment: Alignment.center,
        child: TextFormField(
          //initialValue: nameController.text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: 13),

          keyboardType: TextInputType.text,
          obscureText: true,
          controller: passwordController,

          textInputAction: TextInputAction.next,
          validator: (val) => validatePass(
              val!,
              getTranslated(context, 'PWD_REQUIRED'),
              getTranslated(context, 'PWD_LENGTH')),
          onSaved: (String? value) {
            password = value;
          },
          decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 5,
              ),
              hintText: getTranslated(context, 'PASSHINT_LBL')!,
              hintStyle: TextStyle(
                  color:
                  Theme.of(context).colorScheme.fontColor.withOpacity(0.3),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              fillColor: Theme.of(context).colorScheme.lightWhite,
              border: InputBorder.none),
        ),
      ),
    );
  }

  /* setPass() {
    return Padding(
        padding:
            const EdgeInsetsDirectional.only(start: 25.0, end: 25.0, top: 30.0),
        child: TextFormField(
          keyboardType: TextInputType.text,
          obscureText: true,
          style: Theme.of(context).textTheme.subtitle2!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          controller: passwordController,
          validator: (val) => validatePass(
              val!,
              getTranslated(context, 'PWD_REQUIRED'),
              getTranslated(context, 'PWD_LENGTH')),
          onSaved: (String? value) {
            password = value;
          },
          decoration: InputDecoration(
            prefixIcon: SvgPicture.asset(
              'assets/images/password.svg',
              color: Theme.of(context).colorScheme.fontColor,
            ),
            hintText: getTranslated(context, 'PASSHINT_LBL'),
            hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal),
            // filled: true,
            // fillColor: Theme.of(context).colorScheme.lightWhite,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 40, maxHeight: 25),
            // focusedBorder: OutlineInputBorder(
            //   borderSide: BorderSide(color: Theme.of(context).colorScheme.fontColor),
            //   borderRadius: BorderRadius.circular(10.0),
            // ),
            focusedBorder: UnderlineInputBorder(
              borderSide: const BorderSide(color: colors.primary),
              borderRadius: BorderRadius.circular(7.0),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
              borderRadius: BorderRadius.circular(7.0),
            ),
          ),
        ));
  }*/

  setConfirmpss() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
        height: 53,
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.lightWhite,
          borderRadius: BorderRadius.circular(10.0),
        ),
        alignment: Alignment.center,
        child: TextFormField(
          //initialValue: nameController.text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: 13),

          keyboardType: TextInputType.text,
          obscureText: true,

          controller: confirmpassController,
          validator: (value) {
            if (value!.isEmpty) {
              return getTranslated(context, 'CON_PASS_REQUIRED_MSG');
            }
            if (value != password) {
              return getTranslated(context, 'CON_PASS_NOT_MATCH_MSG');
            } else {
              return null;
            }
          },
          onSaved: (String? value) {
            comfirmpass = value;
          },
          decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 5,
              ),
              hintText: getTranslated(context, 'CONFIRMPASSHINT_LBL')!,
              hintStyle: TextStyle(
                  color:
                  Theme.of(context).colorScheme.fontColor.withOpacity(0.3),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              fillColor: Theme.of(context).colorScheme.lightWhite,
              border: InputBorder.none),
        ),
      ),
    );
  }

/*  setConfirmpss() {
    return Padding(
        padding:
            const EdgeInsetsDirectional.only(start: 25.0, end: 25.0, top: 20.0),
        child: TextFormField(
          keyboardType: TextInputType.text,
          obscureText: true,
          style: Theme.of(context).textTheme.subtitle2!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          controller: confirmpassController,
          validator: (value) {
            if (value!.isEmpty) {
              return getTranslated(context, 'CON_PASS_REQUIRED_MSG');
            }
            if (value != password) {
              return getTranslated(context, 'CON_PASS_NOT_MATCH_MSG');
            } else {
              return null;
            }
          },
          onSaved: (String? value) {
            comfirmpass = value;
          },
          decoration: InputDecoration(
            prefixIcon: SvgPicture.asset(
              'assets/images/password.svg',
              color: Theme.of(context).colorScheme.fontColor,
            ),
            hintText: getTranslated(context, 'CONFIRMPASSHINT_LBL'),
            hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal),
            // filled: true,
            // fillColor: Theme.of(context).colorScheme.lightWhite,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 40, maxHeight: 25),
            // focusedBorder: OutlineInputBorder(
            //   borderSide: BorderSide(color: Theme.of(context).colorScheme.fontColor),
            //   borderRadius: BorderRadius.circular(10.0),
            // ),
            enabledBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ));
  }*/

  backBtn() {
    return Platform.isIOS
        ? Container(
        padding: const EdgeInsetsDirectional.only(top: 20.0, start: 10.0),
        alignment: Alignment.topLeft,
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 4.0),
            child: InkWell(
              child: const Icon(Icons.keyboard_arrow_left,
                  color: colors.primary),
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ))
        : Container();
  }

  @override
  void initState() {
    super.initState();
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  setPassBtn() {
    return Center(
      child: Padding(
          padding: const EdgeInsetsDirectional.only(top: 20.0, bottom: 20.0),
          child: AppBtn(
            title: getTranslated(context, 'SET_PASSWORD'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              validateAndSubmit();
            },
          )),
    );
  }

  expandedBottomView() {
    return Expanded(
        child: SingleChildScrollView(
          child: Form(
            key: _formkey,
            child: Card(
              elevation: 0.5,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsetsDirectional.only(
                  start: 20.0, end: 20.0, top: 20.0),
              child: Column(
                children: [
                  forgotpassTxt(),
                  setPass(),
                  setConfirmpss(),
                  setPassBtn(),
                ],
              ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.white,
        key: _scaffoldKey,
        body: _isNetworkAvail
            ? Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
                top: 23,
                left: 23,
                right: 23,
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getLogo(),
                  forgotpassTxt(),
                  setPass(),
                  setConfirmpss(),
                  setPassBtn(),
                  /* signUpTxt(),
                  verifyCodeTxt(),
                  setCodeWithMono(),
                  verifyBtn(),*/
                  /* SizedBox(
                          height: deviceHeight! * 0.1,
                        ),
                        termAndPolicyTxt(),*/
                ],
              ),
            ),
          ),
        )
            : noInternet(context));
  }

  Widget getLogo() {

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 60),
      child: Image.asset(
        'assets/images/baby.png',
        alignment: Alignment.center,
        height: 90,
        width: 90,
        fit: BoxFit.contain,
      ),
    );
  }

  getLoginContainer() {
    return Positioned.directional(
      start: MediaQuery.of(context).size.width * 0.025,
      // end: width * 0.025,
      // top: width * 0.45,
      top: MediaQuery.of(context).size.height * 0.2, //original
      //    bottom: height * 0.1,
      textDirection: Directionality.of(context),
      child: ClipPath(
        clipper: ContainerClipper(),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom * 0.8),
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.95,
          color: Theme.of(context).colorScheme.white,
          child: Form(
            key: _formkey,
            child: ScrollConfiguration(
              behavior: MyBehavior(),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.10,
                      ),
                      forgotpassTxt(),
                      setPass(),
                      setConfirmpss(),
                      setPassBtn(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
