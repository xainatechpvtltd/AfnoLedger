import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/GlobalComponents/button_global.dart';
import 'package:mobile_pos/Screens/Home/home.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../Provider/add_to_cart.dart';
import '../../currency.dart';

class PaymentCompleted extends StatefulWidget {
  const PaymentCompleted({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PaymentCompletedState createState() => _PaymentCompletedState();
}

class _PaymentCompletedState extends State<PaymentCompleted> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(builder: (context, ref, __) {
      final providerData = ref.watch(cartNotifier);
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            lang.S.of(context).paymentComplete,
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.0,
          actions: [
            PopupMenuButton(
              itemBuilder: (BuildContext bc) => [
                const PopupMenuItem(value: "/addPromoCode", child: Text('Add Promo Code')),
                const PopupMenuItem(value: "/addDiscount", child: Text('Add Discount')),
                const PopupMenuItem(value: "/settings", child: Text('Cancel All Product')),
                const PopupMenuItem(value: "/settings", child: Text('Vat Doesn\'t Apply')),
              ],
              onSelected: (value) {
                Navigator.pushNamed(context, '$value');
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Center(
                child: Image(
                  image: AssetImage('images/complete.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 5.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Text(lang.S.of(context).total,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: kGreyTextColor,
                                )),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              providerData.getTotalAmount().toString(),
                              style: theme.textTheme.titleLarge?.copyWith(color: kGreyTextColor),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                        child: SizedBox(
                          height: 50.0,
                          width: 1.0,
                          child: Container(
                            color: kGreyTextColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Text(
                              lang.S.of(context).retur,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: kGreyTextColor,
                              ),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              '$currency 00.00',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: kGreyTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(
                  Icons.payment,
                  color: kGreyTextColor,
                ),
                title: Text('${lang.S.of(context).invoice}: #121342'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: kGreyTextColor,
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.payment,
                  color: kGreyTextColor,
                ),
                title: Text(lang.S.of(context).sendEmail),
                trailing: const Icon(
                  Icons.email,
                  color: kGreyTextColor,
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.payment,
                  color: kGreyTextColor,
                ),
                title: Text(lang.S.of(context).sendSms),
                trailing: const Icon(
                  Icons.message_outlined,
                  color: kGreyTextColor,
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.payment,
                  color: kGreyTextColor,
                ),
                title: Text(lang.S.of(context).recivethePin),
                trailing: const Icon(
                  Icons.local_print_shop,
                  color: kGreyTextColor,
                ),
              ),
              ElevatedButton(
                child: Text(lang.S.of(context).startNewSale),
                onPressed: () {
                  // providerData.clearCart();
                  // providerData.clearDiscount();
                  const Home().launch(context);
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
