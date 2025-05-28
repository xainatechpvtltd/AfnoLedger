import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/GlobalComponents/returned_tag_widget.dart';
import 'package:mobile_pos/model/sale_transaction_model.dart';
import 'package:nb_utils/nb_utils.dart';

import '../PDF Invoice/sales_invoice_pdf.dart';
import '../PDF Invoice/pdf_common_functions.dart';
import '../Provider/add_to_cart.dart';
import '../Provider/profile_provider.dart';
import '../Screens/Sales/add_sales.dart';
import '../Screens/invoice return/invoice_return_screen.dart';
import '../Screens/invoice_details/sales_invoice_details_screen.dart';
import '../constant.dart';
import '../core/theme/_app_colors.dart';
import '../currency.dart';
import '../generated/l10n.dart' as lang;
import '../model/business_info_model.dart' as bInfo;
import '../thermal priting invoices/model/print_transaction_model.dart';
import '../thermal priting invoices/provider/print_thermal_invoice_provider.dart';

Widget salesTransactionWidget({
  required BuildContext context,
  required SalesTransactionModel sale,
  required bInfo.BusinessInformation businessInfo,
  required WidgetRef ref,
  bool? showProductQTY,
  required bool advancePermission,
  num? returnAmount,
}) {
  final theme = Theme.of(context);
  final businessSettingData = ref.watch(businessSettingProvider);
  final printerData = ref.watch(thermalPrinterProvider);
  return Column(
    children: [
      InkWell(
        onTap: () {
          SalesInvoiceDetails(
            saleTransaction: sale,
            businessInfo: businessInfo,
          ).launch(context);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          width: context.width(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      (showProductQTY ?? false) ? "${lang.S.of(context).totalProduct} : ${sale.salesDetails?.length.toString()}" : sale.party?.name ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '#${sale.invoiceNumber}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ///_____Payment_Sttus________________________________________
                      getPaymentStatusBadge(context: context, dueAmount: sale.dueAmount!, totalAmount: sale.totalAmount!),

                      ///________Return_tag_________________________________________
                      ReturnedTagWidget(show: sale.salesReturns?.isNotEmpty ?? false),
                    ],
                  ),
                  Text(
                    DateFormat.yMMMd().format(DateTime.parse(sale.saleDate ?? '')),
                    style: const TextStyle(color: DAppColors.kSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lang.S.of(context).total} : $currency${sale.totalAmount.toString()}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: DAppColors.kSecondary),
                  ),
                  const SizedBox(width: 4),
                  if (sale.dueAmount!.toInt() != 0)
                    Text(
                      '${lang.S.of(context).paid} : $currency${(sale.totalAmount!.toDouble() - sale.dueAmount!.toDouble()).toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: DAppColors.kSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (sale.dueAmount!.toInt() == 0)
                    Text(
                      (returnAmount != null)
                          ? 'Returned Amount: $currency$returnAmount'
                          : '${lang.S.of(context).paid} : $currency${(sale.totalAmount!.toDouble() - sale.dueAmount!.toDouble()).toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                    ),
                  if (sale.dueAmount!.toInt() != 0)
                    Text(
                      (returnAmount != null)
                          ? 'Returned Amount: $currency${returnAmount.toStringAsFixed(2)}'
                          : '${lang.S.of(context).due}: $currency${sale.dueAmount?.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                    ),
                  Row(
                    children: [
                      IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          onPressed: () async {
                            PrintTransactionModel model = PrintTransactionModel(transitionModel: sale, personalInformationModel: businessInfo);
                            await printerData.printSalesThermalInvoiceNow(
                              transaction: model,
                              productList: model.transitionModel!.salesDetails,
                              context: context,
                            );
                          },
                          icon: const Icon(
                            FeatherIcons.printer,
                            color: Colors.grey,
                          )),
                      const SizedBox(width: 10),
                      businessSettingData.when(data: (business) {
                        return IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            onPressed: () => SalesInvoicePdf.generateSaleDocument(sale, businessInfo, context, business),
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.grey,
                            ));
                      }, error: (e, stack) {
                        return Text(e.toString());
                      }, loading: () {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }),
                      if (advancePermission) const SizedBox(width: 10),

                      ///_________Sales_edit___________________________
                      if (advancePermission)
                        Visibility(
                          visible: !(sale.salesReturns?.isNotEmpty ?? false),
                          child: IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                              onPressed: () async {
                                ref.refresh(cartNotifier);
                                AddSalesScreen(
                                  transitionModel: sale,
                                  customerModel: null,
                                ).launch(context);
                              },
                              icon: const Icon(
                                FeatherIcons.edit,
                                color: Colors.grey,
                              )),
                        ),

                      ///________Sales_return_____________________________
                      if (advancePermission)
                        PopupMenuButton(
                          offset: const Offset(0, 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: EdgeInsets.zero,
                          itemBuilder: (BuildContext bc) => [
                            ///________Sale Return___________________________________
                            PopupMenuItem(
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InvoiceReturnScreen(saleTransactionModel: sale),
                                    ),
                                  );
                                  Navigator.pop(bc);
                                },
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.keyboard_return_outlined,
                                      color: kGreyTextColor,
                                    ),
                                    SizedBox(width: 10.0),
                                    Text(
                                      'Sale return',
                                      style: TextStyle(color: kGreyTextColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            Navigator.pushNamed(context, '$value');
                          },
                          child: const Icon(
                            FeatherIcons.moreVertical,
                            color: kGreyTextColor,
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      const Divider(height: 0),
    ],
  );
}

Widget getPaymentStatusBadge({required num dueAmount, required num totalAmount, required BuildContext context}) {
  String status;
  Color textColor;
  Color bgColor;

  if (dueAmount <= 0) {
    status = lang.S.of(context).paid;
    textColor = const Color(0xff0dbf7d);
    bgColor = const Color(0xff0dbf7d).withOpacity(0.1);
  } else if (dueAmount >= totalAmount) {
    status = lang.S.of(context).unPaid;
    textColor = const Color(0xFFED1A3B);
    bgColor = const Color(0xFFED1A3B).withOpacity(0.1);
  } else {
    status = 'Partial Paid';
    textColor = const Color(0xFFFFA500);
    bgColor = const Color(0xFFFFA500).withOpacity(0.1);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: const BorderRadius.all(Radius.circular(2)),
    ),
    child: Text(
      status,
      style: TextStyle(color: textColor),
    ),
  );
}
