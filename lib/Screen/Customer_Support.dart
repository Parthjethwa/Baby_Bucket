import 'dart:async';
import 'dart:convert';
import 'package:pinko_implex/Helper/AppBtn.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'Chat.dart';
import '../Helper/Color.dart';
import 'package:pinko_implex/Helper/Session.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../Helper/Constant.dart';
import '../Helper/SimBtn.dart';
import '../Helper/String.dart';
import '../Model/Model.dart';

class CustomerSupport extends StatefulWidget {
  const CustomerSupport({Key? key}) : super(key: key);

  @override
  _CustomerSupportState createState() => _CustomerSupportState();
}

class _CustomerSupportState extends State<CustomerSupport>
    with TickerProviderStateMixin {
  bool _isLoading = true, _isProgress = false;
  Animation? buttonSqueezeanimation;
  late AnimationController buttonController;
  bool _isNetworkAvail = true;
  List<Model> typeList = [];
  List<Model> ticketList = [];
  List<Model> statusList = [];
  List<Model> tempList = [];
  String? type, email, title, desc, status, id;
  FocusNode? nameFocus, emailFocus, descFocus;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final descController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool edit = false, show = false;
  bool fabIsVisible = true;
  ScrollController controller = ScrollController();
  int offset = 0;
  int total = 0, curEdit = -1;
  bool isLoadingmore = true;

  @override
  void initState() {
    super.initState();
    statusList = [
      Model(id: '3', title: 'Resolved'),
      Model(id: '5', title: 'Reopen')
    ];
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));
    controller = ScrollController();
    controller.addListener(() {
      setState(() {
        fabIsVisible =
            controller.position.userScrollDirection == ScrollDirection.forward;

        if (controller.offset >= controller.position.maxScrollExtent &&
            !controller.position.outOfRange) {
          isLoadingmore = true;

          if (offset < total) getTicket();
        }
      });
    });
    getType();
    getTicket();
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    emailController.dispose();
    descController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          getSimpleAppBar(getTranslated(context, 'CUSTOMER_SUPPORT')!, context),
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: fabIsVisible ? 1 : 0,
        child: FloatingActionButton(
          onPressed: () async {
            setState(() {
              edit = false;
              show = !show;

              clearAll();
            });
          },
          heroTag: null,
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary,
            ),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.fontColor,
            ),
          ),
        ),
      ),
      body: _isNetworkAvail
          ? _isLoading
              ? shimmer(context)
              : Stack(children: [
                  SingleChildScrollView(
                      controller: controller,
                      child: Form(
                        key: _formkey,
                        child: Column(
                          children: [
                            show
                                ? Card(
                                    elevation: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          setType(),
                                          setEmail(),
                                          setTitle(),
                                          setDesc(),
                                          Row(
                                            children: [
                                              edit
                                                  ? statusDropDown()
                                                  : Container(),
                                              const Spacer(),
                                              sendButton(),
                                            ],
                                          )
                                        ],
                                      ),
                                    ))
                                : Container(),
                            ticketList.isNotEmpty
                                ? ListView.separated(
                                    separatorBuilder:
                                        (BuildContext context, int index) =>
                                            const Divider(),
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: (offset < total)
                                        ? ticketList.length + 1
                                        : ticketList.length,
                                    itemBuilder: (context, index) {
                                      return (index == ticketList.length &&
                                              isLoadingmore)
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : ticketItem(index);
                                    })
                                : SizedBox(
                                    height: deviceHeight! -
                                        kToolbarHeight -
                                        MediaQuery.of(context).padding.top,
                                    child: getNoItem(context))
                          ],
                        ),
                      )),
                  showCircularProgress(_isProgress, colors.primary),
                ])
          : noInternet(context),
    );
  }

  Widget setType() {
    return DropdownButtonFormField(
      iconEnabledColor: Theme.of(context).colorScheme.fontColor,
      isDense: true,
      hint: Container(
        width: deviceWidth! * 0.7,
        child: Text(
          getTranslated(context, 'SELECT_TYPE')!,
          style: Theme.of(context).textTheme.subtitle2!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: true,
        ),
      ),
      decoration: InputDecoration(
        filled: true,
        isDense: true,
        fillColor: Theme.of(context).colorScheme.lightWhite,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.fontColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.lightWhite),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      value: type,
      style: Theme.of(context)
          .textTheme
          .subtitle2!
          .copyWith(color: Theme.of(context).colorScheme.fontColor),
      onChanged: (String? newValue) {
        if (mounted) {
          setState(() {
            type = newValue;
          });
        }
      },
      items: typeList.map((Model user) {
        return DropdownMenuItem<String>(
          value: user.id,
          child: Text(
            user.title!,
          ),
        );
      }).toList(),
    );
  }

  void validateAndSubmit() async {
    if (edit) {
      if ((type == null || status == null) ||
          (status == null && type == null)) {
        setSnackbar('Please Select Type');
      } else if (validateAndSave()) {
        checkNetwork();
      }
    } else {
      if (type == null) {
        setSnackbar('Please Select Type');
      } else if (validateAndSave()) {
        checkNetwork();
      }
    }
  }

  Future<void> checkNetwork() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      sendRequest();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
        await buttonController.reverse();
      });
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  setEmail() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 10.0,
      ),
      child: TextFormField(
        keyboardType: TextInputType.emailAddress,
        focusNode: emailFocus,
        textInputAction: TextInputAction.next,
        controller: emailController,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
        validator: (val) => validateEmail(
            val!,
            getTranslated(context, 'EMAIL_REQUIRED'),
            getTranslated(context, 'VALID_EMAIL')),
        onSaved: (String? value) {
          email = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus!, nameFocus);
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, 'EMAILHINT_LBL'),
          hintStyle: Theme.of(context).textTheme.subtitle2!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  setTitle() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 10.0,
      ),
      child: TextFormField(
        focusNode: nameFocus,
        textInputAction: TextInputAction.next,
        controller: nameController,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
        validator: (val) =>
            validateField(val!, getTranslated(context, 'FIELD_REQUIRED')),
        onSaved: (String? value) {
          title = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus!, nameFocus);
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, 'TITLE'),
          hintStyle: Theme.of(context).textTheme.subtitle2!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  setDesc() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 10.0,
      ),
      child: TextFormField(
        focusNode: descFocus,
        controller: descController,
        maxLines: null,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
        validator: (val) =>
            validateField(val!, getTranslated(context, 'FIELD_REQUIRED')),
        onSaved: (String? value) {
          desc = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus!, nameFocus);
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, 'DESCRIPTION'),
          hintStyle: Theme.of(context).textTheme.subtitle2!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode? nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  Future<void> getType() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        Response response = await post(getTicketTypeApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata['error'];
        String? msg = getdata['message'];
        if (!error) {
          var data = getdata['data'];

          typeList =
              (data as List).map((data) => Model.fromSupport(data)).toList();
        } else {
          setSnackbar(msg!);
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  Future<void> getTicket() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };

        Response response =
            await post(getTicketApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata['error'];
        String? msg = getdata['message'];
        if (!error) {
          var data = getdata['data'];
          total = int.parse(getdata['total']);

          if ((offset) < total) {
            tempList.clear();
            var data = getdata['data'];
            tempList =
                (data as List).map((data) => Model.fromTicket(data)).toList();

            ticketList.addAll(tempList);

            offset = offset + perPage;
          }
        } else {
          if (msg != 'Ticket(s) does not exist') setSnackbar(msg!);
          isLoadingmore = false;
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
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
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }

  Widget sendButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: SimBtn(
          borderRadius: circularBorderRadius5,
          size: 0.4,
          title: getTranslated(context, 'SEND'),
          onBtnSelected: () {
            validateAndSubmit();
          }),
    );
  }

  Future<void> sendRequest() async {
    if (mounted) {
      setState(() {
        _isProgress = true;
      });
    }

    try {
      var data = {
        USER_ID: CUR_USERID,
        SUB: title,
        DESC: desc,
        TICKET_TYPE: type,
        EMAIL: email,
      };
      if (edit) {
        data[TICKET_ID] = id;
        data[STATUS] = status;
      }

      Response response = await post(edit ? editTicketApi : addTicketApi,
              body: data, headers: headers)
          .timeout(const Duration(seconds: timeOut));

      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata['error'];
        String msg = getdata['message'];
        if (!error) {
          var data = getdata['data'];
          if (mounted) {
            setState(() {
              if (edit) {
                ticketList[curEdit] = Model.fromTicket(data[0]);
              } else {
                ticketList.add(Model.fromTicket(data[0]));
              }
            });
          }
        }
        setSnackbar(msg);
        setState(() {
          edit = false;
          _isProgress = false;
          clearAll();
        });
      }
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!);
    }
  }

  clearAll() {
    type = null;
    email = null;
    title = null;
    desc = null;
    FocusScope.of(context).unfocus();
  }

  Widget ticketItem(int index) {
    Color back;
    String? status = ticketList[index].status;
    //1 -> pending, 2 -> opened, 3 -> resolved, 4 -> closed, 5 -> reopened
    if (status == '1') {
      back = Colors.orange;
      status = 'Pending';
    } else if (status == '2') {
      back = Colors.cyan;
      status = 'Opened';
    } else if (status == '3') {
      back = Colors.green;
      status = 'Resolved';
    } else if (status == '5') {
      back = Colors.cyan;
      status = 'Reopen';
    } else {
      back = Colors.red;
      status = 'Close';
    }
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => Chat(
                  id: ticketList[index].id,
                  status: ticketList[index].status,
                ),
              ));
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Type : ${ticketList[index].type!}'),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                        color: back,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4.0))),
                    child: Text(
                      status,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.white),
                    ),
                  )
                ],
              ),
              Text(
                  '${getTranslated(context, 'TITLE')!} : ${ticketList[index].title!}'),
              Text(
                '${getTranslated(context, 'DESCRIPTION')!} : ${ticketList[index].desc!}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                  '${getTranslated(context, 'DATE')!} : ${ticketList[index].date!}'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    GestureDetector(
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(start: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.lightWhite,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4.0),
                            ),
                          ),
                          child: Text(
                            getTranslated(context, 'EDIT')!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontSize: 11),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            edit = true;
                            show = true;
                            curEdit = index;
                            id = ticketList[index].id;
                            emailController.text = ticketList[index].email!;
                            nameController.text = ticketList[index].title!;
                            descController.text = ticketList[index].desc!;
                            type = ticketList[index].typeId;
                          });
                        }),
                    GestureDetector(
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(start: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.lightWhite,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4.0))),
                          child: Text(
                            getTranslated(context, 'CHAT')!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontSize: 11),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => Chat(
                                  id: ticketList[index].id,
                                  status: ticketList[index].status,
                                ),
                              ));
                        }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  statusDropDown() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * .4,
      child: DropdownButtonFormField(
        iconEnabledColor: Theme.of(context).colorScheme.fontColor,
        isDense: true,
        hint: Text(
          getTranslated(context, 'SELECT_TYPE')!,
          style: Theme.of(context).textTheme.subtitle2!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
        ),
        decoration: InputDecoration(
          filled: true,
          isDense: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        value: status,
        style: Theme.of(context)
            .textTheme
            .subtitle2!
            .copyWith(color: Theme.of(context).colorScheme.fontColor),
        onChanged: (String? newValue) {
          if (mounted) {
            setState(() {
              status = newValue;
            });
          }
        },
        items: statusList.map((Model user) {
          return DropdownMenuItem<String>(
            value: user.id,
            child: Text(
              user.title!,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
                  await buttonController.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }
}
