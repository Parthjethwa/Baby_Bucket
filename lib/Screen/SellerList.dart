import 'package:cached_network_image/cached_network_image.dart';
import 'package:pinko_implex/Helper/Color.dart';
import 'package:pinko_implex/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'HomePage.dart';
import 'Seller_Details.dart';

class SellerList extends StatefulWidget {
  const SellerList({Key? key}) : super(key: key);

  @override
  _SellerListState createState() => _SellerListState();
}

class _SellerListState extends State<SellerList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getAppBar(
            getTranslated(context, 'SHOP_BY_SELLER')!, context, setStateNow),
        body: GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 3,
            shrinkWrap: true,
            childAspectRatio: .8,
            children: List.generate(
              sellerList.length,
              (index) {
                return catItem(index, context);
              },
            )));
  }

  setStateNow() {
    setState(() {});
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

  Widget catItem(int index, BuildContext context) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(25.0),
                  child: FadeInImage(
                    image: CachedNetworkImageProvider(
                        sellerList[index].seller_profile!),
                    fadeInDuration: const Duration(milliseconds: 150),
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) =>
                        erroWidget(50),
                    placeholder: placeHolder(50),
                  )),
            ),
          ),
          Text(
            '${sellerList[index].seller_name!}\n',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .caption!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
          )
        ],
      ),
      onTap: () {
        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => SellerProfile(
                      sellerStoreName: sellerList[index].store_name ?? '',
                      sellerRating: sellerList[index].seller_rating ?? '',
                      sellerImage: sellerList[index].seller_profile ?? '',
                      sellerName: sellerList[index].seller_name ?? '',
                      sellerID: sellerList[index].seller_id,
                      storeDesc: sellerList[index].store_description,
                    )));
      },
    );
  }
}
