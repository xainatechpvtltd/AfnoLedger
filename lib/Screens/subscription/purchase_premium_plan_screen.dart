import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../GlobalComponents/button_global.dart';
import '../../constant.dart';
import '../../model/business_info_model.dart' as bInfo;
import '../../GlobalComponents/go_to_subscription-package_page_popup_widget.dart';
import '../Currency/Model/currency_model.dart';
import '../Currency/Provider/currency_provider.dart';
import '../Home/home.dart';
import '../payment getway/payment_getway_screen.dart';
import 'Model/subscription_plan_model.dart';
import 'Provider/subacription_plan_provider.dart';

class PurchasePremiumPlanScreen extends StatefulWidget {
  const PurchasePremiumPlanScreen({super.key, required this.isCameBack, this.isExpired, this.enrolledPlan, this.willExpire});

  final bool isCameBack;
  final bool? isExpired;
  final bInfo.EnrolledPlan? enrolledPlan;
  final String? willExpire;

  @override
  State<PurchasePremiumPlanScreen> createState() => _PurchasePremiumPlanScreenState();
}

class _PurchasePremiumPlanScreenState extends State<PurchasePremiumPlanScreen> {
  SubscriptionPlanModel? selectedPlan;
  bool isPlanExpiringIn7Days = false;

  List<String> imageList = [
    'images/sp1.png',
    'images/sp2.png',
    'images/sp3.png',
    'images/sp4.png',
    'images/sp5.png',
    'images/sp6.png',
  ];

  List<String> planDetailsImages = [
    'images/plan_details_1.png',
    'images/plan_details_2.png',
    'images/plan_details_3.png',
    'images/plan_details_4.png',
    'images/plan_details_5.png',
    'images/plan_details_6.png',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isExpired == true) {
        getUpgradeDialog();
      }
    });
  }

  CurrencyModel? getDefoultCurrency({required List<CurrencyModel> currencies}) {
    for (var element in currencies) {
      if (element.isDefault ?? false) {
        return element;
      }
    }
    return null;
  }

  // warning popup
  void getUpgradeDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return goToPackagePagePopup(context: context, enrolledPlan: widget.enrolledPlan, navigateBack: true);
        });
  }

  bool _isRefreshing = false; // Prevents multiple refresh calls

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    ref.refresh(businessInfoProvider);
    ref.refresh(subscriptionPlanProvider);
    ref.refresh(getExpireDateProvider(ref));

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  @override
  void initState() {
    selectedPlan = SubscriptionPlanModel(id: widget.enrolledPlan?.planId);
    if (widget.willExpire != null && DateTime.tryParse(widget.willExpire ?? '') != null) {
      DateTime expiryDate = DateTime.parse(widget.willExpire!);
      isPlanExpiringIn7Days = expiryDate.isBefore(DateTime.now().add(const Duration(days: 6)));
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<String> planDetailsText = [
      lang.S.of(context).freeLifetimeUpdate,
      lang.S.of(context).android,
      lang.S.of(context).premiumCustomerSupport,
      lang.S.of(context).customInvoiceBranding,
      lang.S.of(context).unlimitedUsage,
      lang.S.of(context).freeDataBackup,
    ];
    List<String> titleListData = [
      lang.S.of(context).freeLifetimeUpdate,
      lang.S.of(context).android,
      lang.S.of(context).premiumCustomerSupport,
      lang.S.of(context).customInvoiceBranding,
      lang.S.of(context).unlimitedUsage,
      lang.S.of(context).freeDataBackup,
    ];

    return Consumer(builder: (context, ref, __) {
      final subscriptionPlanData = ref.watch(subscriptionPlanProvider);
      final businessInfo = ref.watch(businessInfoProvider);
      final currencyData = ref.watch(currencyProvider);
      return Scaffold(
        backgroundColor: kWhite,
        body: PopScope(
          canPop: widget.isExpired != true,
          child: RefreshIndicator(
            onRefresh: () => refreshData(ref),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.S.of(context).purchasePremium,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          GestureDetector(
                            onTap: widget.isExpired != true
                                ? () {
                                    if (widget.isCameBack) {
                                      Navigator.pop(context);
                                    } else {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (context) => const Home()),
                                        (Route<dynamic> route) => false,
                                      );
                                    }
                                  }
                                : () => Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const Home()),
                                      (Route<dynamic> route) => false,
                                    ),
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(
                            //     backgroundColor: Colors.red,
                            //     content: Text('Please update your plan'),
                            //   ),
                            // ),

                            child: Icon(
                              Icons.cancel_outlined,
                              color: widget.isExpired != true ? Colors.grey : Colors.black,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                          itemCount: imageList.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (_, i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                GestureDetector(
                                                  child: const Icon(Icons.cancel),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                                const SizedBox(width: 20),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Image(
                                              height: 200,
                                              width: 200,
                                              image: AssetImage(planDetailsImages[i]),
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              planDetailsText[i],
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 15),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(lang.S.of(context).loremIpsumDolor,
                                                  //'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Natoque aliquet et, cur eget. Tellus sapien odio aliq.',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 16)),
                                            ),
                                            const SizedBox(height: 20),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: kWhite, boxShadow: [
                                    BoxShadow(color: const Color(0xff0C1A4B).withOpacity(0.24), blurRadius: 1),
                                    BoxShadow(color: const Color(0xff473232).withOpacity(0.05), offset: const Offset(0, 3), blurRadius: 8, spreadRadius: -1)
                                  ]),
                                  child: ListTile(
                                    visualDensity: const VisualDensity(horizontal: -4),
                                    contentPadding: const EdgeInsets.only(left: 8, right: 10),
                                    leading: SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: Image(
                                        image: AssetImage(imageList[i]),
                                      ),
                                    ),
                                    title: Text(
                                      titleListData[i],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    trailing: const Icon(
                                      FeatherIcons.alertCircle,
                                      color: kGreyTextColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                      const SizedBox(height: 10),
                      Text(
                        lang.S.of(context).buyPremium,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      ///_______Plans_List______________________________________________________________
                      subscriptionPlanData.when(data: (data) {
                        return SizedBox(
                          height: (context.width() / 2.5) + 18,
                          child: ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: data.length,
                            itemBuilder: (BuildContext context, int index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedPlan = data[index];
                                  });
                                },
                                child: (data[index].offerPrice != null && (data[index].offerPrice ?? 0) > 0)
                                    ? Padding(
                                        padding: const EdgeInsets.only(right: 10),
                                        child: SizedBox(
                                          height: (context.width() / 3) + 18,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 20, top: 20),
                                                child: Container(
                                                  // height: (context.width() / 3) - 20,
                                                  width: (context.width() / 3) - 20,
                                                  decoration: BoxDecoration(
                                                    color: data[index].id == selectedPlan?.id ? kPremiumPlanColor2.withOpacity(0.1) : Colors.white,
                                                    borderRadius: const BorderRadius.all(
                                                      Radius.circular(10),
                                                    ),
                                                    border: Border.all(
                                                      width: 1,
                                                      color: data[index].id == selectedPlan?.id ? kPremiumPlanColor2 : kPremiumPlanColor,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        data[index].subscriptionName ?? '',
                                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                      ),
                                                      Text(
                                                        '${data[index].duration} days',
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${getDefoultCurrency(currencies: currencyData.value ?? [])?.symbol ?? ''}${data[index].offerPrice}',
                                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPremiumPlanColor2),
                                                      ),
                                                      Text(
                                                        '${getDefoultCurrency(currencies: currencyData.value ?? [])?.symbol ?? ''}${data[index].subscriptionPrice}',
                                                        style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 14, color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                left: 0,
                                                child: Container(
                                                  height: 25,
                                                  width: 70,
                                                  decoration: const BoxDecoration(
                                                    color: kPremiumPlanColor2,
                                                    borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(10),
                                                      bottomRight: Radius.circular(10),
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      // 'Save ${(100 - (((data[index].offerPrice ?? 0) * 100) / (data[index].subscriptionPrice ?? 0))).round().toString()}%',
                                                      '${lang.S.of(context).save} ${(100 - (((data[index].offerPrice ?? 0) * 100) / (data[index].subscriptionPrice ?? 0))).round().toString()}%',
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.only(bottom: 20, top: 20, right: 10),
                                        child: Container(
                                          width: (context.width() / 3) - 20,
                                          decoration: BoxDecoration(
                                            color: data[index].id == selectedPlan?.id ? kPremiumPlanColor2.withOpacity(0.1) : Colors.white,
                                            borderRadius: const BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                            border: Border.all(width: 1, color: data[index].id == selectedPlan?.id ? kPremiumPlanColor2 : kPremiumPlanColor),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                data[index].subscriptionName ?? '',
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              Text(
                                                //'${data[index].duration} days',
                                                '${data[index].duration} ${lang.S.of(context).days}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                '${getDefoultCurrency(currencies: currencyData.value ?? [])?.symbol ?? ''}${data[index].subscriptionPrice.toString()}',
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPremiumPlanColor),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                              );
                            },
                          ),
                        );
                      }, error: (Object error, StackTrace? stackTrace) {
                        return Text(error.toString());
                      }, loading: () {
                        return const Center(child: CircularProgressIndicator());
                      }),
                      const SizedBox(height: 20),
                      Visibility(
                        visible: (selectedPlan != null &&
                            (widget.enrolledPlan?.planId != selectedPlan?.id || isPlanExpiringIn7Days) &&
                            ((widget.enrolledPlan?.duration ?? 0) < (selectedPlan?.duration ?? 0)) &&
                            (selectedPlan?.offerPrice != null ? selectedPlan!.offerPrice! > 0 : (selectedPlan?.subscriptionPrice ?? 0) > 0)),
                        child: GestureDetector(
                          onTap: () async {
                            if (selectedPlan != null) {
                              bool success = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentScreen(
                                      planId: selectedPlan?.id.toString() ?? '',
                                      businessId: businessInfo.value?.id.toString() ?? '',
                                    ),
                                  ));

                              if (success) {
                                ref.refresh(businessInfoProvider);
                                ref.refresh(getExpireDateProvider(ref));
                                widget.isExpired == false;
                                EasyLoading.showSuccess(
                                  lang.S.of(context).successfullyPaid,
                                  // 'successfully paid'
                                );
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const Home()));
                              } else {
                                EasyLoading.showError(
                                  lang.S.of(context).field,
                                  // 'Field'
                                );
                              }
                            }
                          },
                          child: Container(
                            height: 50,
                            decoration: const BoxDecoration(
                              color: kMainColor,
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Center(
                              child: Text(
                                lang.S.of(context).payForSubscribe,
                                style: const TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
