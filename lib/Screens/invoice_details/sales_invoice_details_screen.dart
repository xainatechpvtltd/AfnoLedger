import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import '../../Const/api_config.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart' as mainConstant;
import '../../currency.dart';
import '../../invoice_constant.dart';
import '../../model/business_info_model.dart' as binfo;
import '../../model/sale_transaction_model.dart';
import '../../thermal priting invoices/model/print_transaction_model.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';

class SalesInvoiceDetails extends StatefulWidget {
  const SalesInvoiceDetails({super.key, required this.saleTransaction, required this.businessInfo, this.fromSale});

  final SalesTransactionModel saleTransaction;
  final binfo.BusinessInformation businessInfo;
  final bool? fromSale;

  @override
  State<SalesInvoiceDetails> createState() => _SalesInvoiceDetailsState();
}

class _SalesInvoiceDetailsState extends State<SalesInvoiceDetails> {
  String productName({required num detailsId}) {
    return widget.saleTransaction.salesDetails!.where((element) => element.id == detailsId).first.product?.productName ?? '';
  }

  num productPrice({required num detailsId}) {
    return widget.saleTransaction.salesDetails!.where((element) => element.id == detailsId).first.price ?? 0;
  }

  num getTotalReturndAmount() {
    num totalReturn = 0;
    if (widget.saleTransaction.salesReturns?.isNotEmpty ?? false) {
      for (var returns in widget.saleTransaction.salesReturns!) {
        if (returns.salesReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.salesReturnDetails!) {
            totalReturn += details.returnAmount ?? 0;
          }
        }
      }
    }
    return totalReturn;
  }

  int serialNumber = 1;

  num getReturndDiscountAmount() {
    num totalReturnDiscount = 0;
    if (widget.saleTransaction.salesReturns?.isNotEmpty ?? false) {
      for (var returns in widget.saleTransaction.salesReturns!) {
        if (returns.salesReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.salesReturnDetails!) {
            totalReturnDiscount += ((productPrice(detailsId: details.saleDetailId ?? 0) * (details.returnQty ?? 0)) - ((details.returnAmount ?? 0)));
          }
        }
      }
    }
    return totalReturnDiscount;
  }

  num getTotalForOldInvoice() {
    num total = 0;
    for (var element in widget.saleTransaction.salesDetails!) {
      total += (element.price ?? 0) * getProductQuantity(detailsId: element.id ?? 0);
    }

    return total;
  }

  num getProductQuantity({required num detailsId}) {
    num totalQuantity = widget.saleTransaction.salesDetails?.where((element) => element.id == detailsId).first.quantities ?? 0;
    if (widget.saleTransaction.salesReturns?.isNotEmpty ?? false) {
      for (var returns in widget.saleTransaction.salesReturns!) {
        if (returns.salesReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.salesReturnDetails!) {
            if (details.saleDetailId == detailsId) {
              totalQuantity += details.returnQty ?? 0;
            }
          }
        }
      }
    }

    return totalQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final _lang = lang.S.of(context);
    final _theme = Theme.of(context);
    return Consumer(builder: (context, ref, __) {
      final printerData = ref.watch(thermalPrinterProvider);
      final businessSettingData = ref.watch(businessSettingProvider);
      return SafeArea(
        child: GlobalPopup(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: SingleChildScrollView(
                    child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    //header
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: businessSettingData.when(
                        data: (business) {
                          final isSvg = business.pictureUrl?.endsWith('.svg');
                          final imageUrl = '${APIConfig.domain}${business.pictureUrl}';
                          const placeholder = AssetImage(mainConstant.logo);
                          return business.pictureUrl.isEmptyOrNull
                              ? _buildInvoiceLogo(image: placeholder)
                              : (isSvg ?? false)
                                  ? SvgPicture.network(imageUrl, height: 54.12, width: 52, fit: BoxFit.cover)
                                  : _buildInvoiceLogo(
                                      image: NetworkImage(imageUrl),
                                    );
                        },
                        error: (e, stack) => Text(e.toString()),
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      title: Text(
                        '${widget.businessInfo.companyName}',
                        style: _theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).mobiles} : ',
                          children: [
                            TextSpan(
                              text: widget.businessInfo.phoneNumber.toString(),
                            )
                          ],
                        ),
                      ),
                      trailing: Container(
                        alignment: Alignment.center,
                        // height: 52,
                        width: 110,
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            bottomLeft: Radius.circular(25),
                          ),
                        ),
                        child: Text(
                          lang.S.of(context).invoice,
                          style: _theme.textTheme.titleLarge?.copyWith(
                            color: white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 33.88),
                    //header data
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //bill to
                              Text.rich(
                                TextSpan(
                                  text: '${lang.S.of(context).billTO} : ',
                                  children: [
                                    TextSpan(
                                      text: widget.saleTransaction.party?.name ?? '',
                                    )
                                  ],
                                ),
                              ),
                              //header mobile data
                              Text.rich(
                                TextSpan(
                                  text: '${lang.S.of(context).mobiles} : ',
                                  children: [
                                    TextSpan(
                                      text: widget.saleTransaction.party?.phone ?? (widget.saleTransaction.meta?.customerPhone ?? 'Guest'),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: '${lang.S.of(context).salesBy} ',
                                  children: [
                                    TextSpan(
                                      text: widget.saleTransaction.user?.name ?? '',
                                    )
                                  ],
                                ),
                                textAlign: TextAlign.end,
                              ),
                              Text.rich(
                                TextSpan(
                                  text: '${_lang.inv} : ',
                                  children: [
                                    TextSpan(
                                      text: '#${widget.saleTransaction.invoiceNumber}',
                                    )
                                  ],
                                ),
                                textAlign: TextAlign.end,
                              ),
                              Text.rich(
                                TextSpan(
                                  text: '${lang.S.of(context).date} : ',
                                  children: [
                                    TextSpan(
                                      text: DateFormat.yMMMd().format(DateTime.parse(widget.saleTransaction.saleDate ?? DateTime.now().toString())),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.end,
                              ),
                              Visibility(
                                visible: widget.businessInfo.vatNumber != null,
                                child: Text.rich(
                                  TextSpan(
                                    text: '${widget.businessInfo.vatName ?? 'VAT Number'} : ',
                                    children: [
                                      TextSpan(
                                        text: widget.businessInfo.vatNumber ?? '',
                                      )
                                    ],
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        defaultColumnWidth: const FixedColumnWidth(100), // Set a default fixed width for all columns
                        border: const TableBorder(
                          verticalInside: BorderSide(
                            color: Color(0xffD9D9D9),
                          ),
                          left: BorderSide(
                            color: Color(0xffD9D9D9),
                          ),
                          right: BorderSide(
                            color: Color(0xffD9D9D9),
                          ),
                          bottom: BorderSide(
                            color: Color(0xffD9D9D9),
                          ),
                        ),
                        children: [
                          // Table header row
                          TableRow(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xffC52127),
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _lang.sl,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Container(
                                color: const Color(0xffC52127),
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _lang.item,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Container(
                                color: const Color(0xff000000),
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  lang.S.of(context).quantity,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Container(
                                color: const Color(0xff000000),
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _lang.unitPrice,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Container(
                                color: const Color(0xff000000),
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  lang.S.of(context).totalPrice,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          // Data rows from ListView.builder
                          ...widget.saleTransaction.salesDetails!.asMap().entries.map(
                            (entry) {
                              final i = entry.key; // This is the index
                              final saleDetail = entry.value; // This is the saleDetail object

                              final quantity = getProductQuantity(detailsId: saleDetail.id ?? 0);
                              final totalPrice = (saleDetail.price ?? 0) * quantity;
                              return TableRow(
                                decoration: i % 2 == 0
                                    ? const BoxDecoration(
                                        color: Colors.white,
                                      ) // Odd row color
                                    : BoxDecoration(
                                        color: const Color(0xffC52127).withValues(alpha: 0.07),
                                      ),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      (widget.saleTransaction.salesDetails!.indexOf(saleDetail) + 1).toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      saleDetail.product?.productName ?? '',
                                      maxLines: 2,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      quantity.toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '$currency ${saleDetail.price?.toStringAsFixed(2) ?? '0'}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '$currency ${totalPrice.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    //sub total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //paid by
                        Text(
                          "${_lang.paidVia}: ${widget.saleTransaction.paymentType?.name??'N/A'}",
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).subTotal} : ',
                              children: [
                                TextSpan(
                                  text: '$currency ${getTotalForOldInvoice().toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),

                    ///__________discount______________________
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).discount} : ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                              text: '$currency ${((widget.saleTransaction.discountAmount ?? 0) + getReturndDiscountAmount()).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),

                    ///-------vat-------------------
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${widget.saleTransaction.vat?.name ?? lang.S.of(context).vat} : ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                              text: '$currency ${widget.saleTransaction.vatAmount?.toStringAsFixed(2) ?? '0.0'}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 5),

                    ///__________shipping_charge______________
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: 'Shipping charge : ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                              text: '$currency ${(widget.saleTransaction.shippingCharge?.toStringAsFixed(2) ?? 0)}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 5),

                    ///------------total amount----------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).totalAmount} : ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                              text: '$currency ${(getTotalReturndAmount() + (widget.saleTransaction.totalAmount ?? 0)).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ///______________Returned_Product_______________________________
                    if (widget.saleTransaction.salesReturns!.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          defaultColumnWidth: const FixedColumnWidth(120),
                          border: const TableBorder(
                            verticalInside: BorderSide(color: Color(0xffD9D9D9)),
                            left: BorderSide(color: Color(0xffD9D9D9)),
                            right: BorderSide(color: Color(0xffD9D9D9)),
                            bottom: BorderSide(color: Color(0xffD9D9D9)),
                          ),
                          children: [
                            // Table header row
                            TableRow(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(color: Color(0xffC52127)),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _lang.sl,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(color: Color(0xffC52127)),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _lang.returnedDate,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(color: Color(0xff000000)),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _lang.returnedItem,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(color: Color(0xff000000)),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _lang.quantity,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(color: Color(0xff000000)),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _lang.totalPrice,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            // Data rows
                            for (var i = 0; i < (widget.saleTransaction.salesReturns?.length ?? 0); i++)
                              for (var detailIndex = 0; detailIndex < (widget.saleTransaction.salesReturns?[i].salesReturnDetails?.length ?? 0); detailIndex++)
                                TableRow(
                                  decoration: serialNumber.isOdd
                                      ? const BoxDecoration(
                                          color: Colors.white,
                                        ) // Odd row color
                                      : BoxDecoration(
                                          color: const Color(0xffC52127).withValues(alpha: 0.07),
                                        ),
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        (serialNumber++).toString(),
                                        style: _theme.textTheme.bodyMedium?.copyWith(
                                          color: kGreyTextColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        DateFormat.yMMMd().format(DateTime.parse(widget.saleTransaction.salesReturns?[i].returnDate ?? DateTime.now().toString())),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        productName(detailsId: widget.saleTransaction.salesReturns?[i].salesReturnDetails?[detailIndex].saleDetailId ?? 0),
                                        maxLines: 2,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        widget.saleTransaction.salesReturns?[i].salesReturnDetails?[detailIndex].returnQty.toString() ?? '0',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        '$currency ${(widget.saleTransaction.salesReturns?[i].salesReturnDetails?[detailIndex].returnAmount ?? 0)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),

                    ///__________Total Return amount______________________
                    if (widget.saleTransaction.salesReturns!.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text.rich(
                          TextSpan(
                            text: '${lang.S.of(context).totalReturnAmount} : ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            children: [
                              TextSpan(
                                text: '$currency ${getTotalReturndAmount()}',
                              ),
                            ],
                          ),
                          style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 5),

                    ///-----------total payable-------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).totalPayable} : ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                              text: '$currency ${widget.saleTransaction.totalAmount?.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 5.0),

                    ///-------paid-----------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).paid} : ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                              text: '$currency ${widget.saleTransaction.totalAmount! - widget.saleTransaction.dueAmount!.toDouble()}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 5.0),

                    ///-------------due---------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).due} : ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                              text: '$currency ${widget.saleTransaction.dueAmount}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Visibility(
                      visible: widget.saleTransaction.image?.isNotEmpty ?? false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attachment',
                            style: _theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 100,
                            width: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: const Color(0xffF5F3F3),
                              image: DecorationImage(
                                  image: NetworkImage(
                                    '${APIConfig.domain}${widget.saleTransaction.image}',
                                  ),
                                  fit: BoxFit.contain),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: widget.saleTransaction.meta?.note?.isNotEmpty ?? false,
                      child: Text(
                        'Note: ${widget.saleTransaction.meta?.note.toString() ?? ''}',
                        maxLines: 1,
                        style: _theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Center(
                      child: Text(
                        lang.S.of(context).thakYouForYourPurchase,
                        maxLines: 1,
                        style: _theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ]),
                )),
                bottomNavigationBar: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: GestureDetector(
                        onTap: () async {
                          if (widget.fromSale ?? false) {
                            int count = 0;
                            Navigator.popUntil(context, (route) {
                              return count++ == 2;
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          height: 60,
                          width: context.width() / 3,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.all(
                              Radius.circular(30),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              lang.S.of(context).cancel,
                              //'Cancel',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: GestureDetector(
                        onTap: () async {
                          PrintTransactionModel model = PrintTransactionModel(transitionModel: widget.saleTransaction, personalInformationModel: widget.businessInfo);
                          await printerData.printSalesThermalInvoiceNow(
                            transaction: model,
                            productList: model.transitionModel!.salesDetails,
                            context: context,
                          );
                        },
                        child: Container(
                          height: 60,
                          width: context.width() / 3,
                          decoration: const BoxDecoration(
                            color: mainConstant.kMainColor,
                            borderRadius: BorderRadius.all(
                              Radius.circular(30),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              lang.S.of(context).print,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildInvoiceLogo({required ImageProvider image}) {
    return Container(
      height: 54.12,
      width: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: image,
        ),
      ),
    );
  }
}
