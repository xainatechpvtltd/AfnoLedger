import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Provider/add_to_cart.dart';
import 'package:mobile_pos/Provider/transactions_provider.dart';
import 'package:mobile_pos/core/theme/_app_colors.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../../Provider/profile_provider.dart';
import '../../../constant.dart';
import '../../GlobalComponents/check_subscription.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../GlobalComponents/returned_tag_widget.dart';
import '../../GlobalComponents/sales_transaction_widget.dart';
import '../../PDF Invoice/pdf_common_functions.dart';
import '../../currency.dart';
import '../../thermal priting invoices/model/print_transaction_model.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../../widgets/empty_widget/_empty_widget.dart';
import '../Home/home.dart';
import '../Sales/add_sales.dart';
import '../invoice_details/sales_invoice_details_screen.dart';
import '../invoice return/invoice_return_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SalesListScreenState createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  bool _isRefreshing = false; // Prevents multiple refresh calls

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    ref.refresh(salesTransactionProvider);
    ref.refresh(businessInfoProvider);
    ref.refresh(getExpireDateProvider(ref));
    ref.refresh(thermalPrinterProvider);

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        return await const Home().launch(context, isNewTask: true);
      },
      child: GlobalPopup(
        child: Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            title: Text(
              lang.S.of(context).saleList,
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
          ),
          body: Consumer(builder: (context, ref, __) {
            final providerData = ref.watch(salesTransactionProvider);
            final profile = ref.watch(businessInfoProvider);
            return RefreshIndicator.adaptive(
              onRefresh: () => refreshData(ref),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: providerData.when(data: (transaction) {
                  return transaction.isNotEmpty
                      ? profile.when(data: (shopDetails) {
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transaction.length,
                            itemBuilder: (context, index) {
                              return salesTransactionWidget(
                                context: context,
                                ref: ref,
                                businessInfo: shopDetails,
                                sale: transaction[index],
                                advancePermission: true,
                              );
                            },
                          );
                        }, error: (e, stack) {
                          return Text(e.toString());
                        }, loading: () {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        })
                      : Center(
                          child: EmptyWidget(
                          message: TextSpan(
                            text: lang.S.of(context).addSale,
                          ),
                        ));
                }, error: (e, stack) {
                  return Text(e.toString());
                }, loading: () {
                  return const Center(child: CircularProgressIndicator());
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}
