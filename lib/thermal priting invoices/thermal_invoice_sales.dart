import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../constant.dart';
import '../model/sale_transaction_model.dart';
import 'model/print_transaction_model.dart';

class SalesThermalPrinterInvoice {
  ///________Sales____________________

  Future<void> printSalesTicket({required PrintTransactionModel printTransactionModel, required List<SalesDetails>? productList}) async {
    bool? isConnected = await PrintBluetoothThermal.connectionStatus;
    if (isConnected == true) {
      List<int> bytes = await getSalesTicket(printTransactionModel: printTransactionModel, productList: productList);
      if (printTransactionModel.transitionModel?.salesDetails?.isNotEmpty ?? false) {
        await PrintBluetoothThermal.writeBytes(bytes);
        EasyLoading.showSuccess('Successfully Printed');
      } else {
        toast('No Product Found');
      }
    } else {
      EasyLoading.showError('Unable to connect with printer');
    }
  }

  Future<List<int>> getSalesTicket({required PrintTransactionModel printTransactionModel, required List<SalesDetails>? productList}) async {
    List<DateTime> returnedDates = [];
    String productName({required num detailsId}) {
      return productList!.where((element) => element.id == detailsId).first.product?.productName ?? '';
    }

    num getProductQuantity({required num detailsId}) {
      num totalQuantity = productList!.where((element) => element.id == detailsId).first.quantities ?? 0;
      if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
        for (var returns in printTransactionModel.transitionModel!.salesReturns!) {
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

    num getTotalForOldInvoice() {
      num total = 0;
      for (var element in productList!) {
        total += (element.price ?? 0) * getProductQuantity(detailsId: element.id ?? 0);
      }

      return total;
    }

    num productPrice({required num detailsId}) {
      return productList!.where((element) => element.id == detailsId).first.price ?? 0;
    }

    num getTotalReturndAmount() {
      num totalReturn = 0;
      if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
        for (var returns in printTransactionModel.transitionModel!.salesReturns!) {
          if (returns.salesReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.salesReturnDetails!) {
              totalReturn += details.returnAmount ?? 0;
            }
          }
        }
      }
      return totalReturn;
    }

    num getReturndDiscountAmount() {
      num totalReturnDiscount = 0;
      if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
        for (var returns in printTransactionModel.transitionModel!.salesReturns!) {
          if (returns.salesReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.salesReturnDetails!) {
              totalReturnDiscount += ((productPrice(detailsId: details.saleDetailId ?? 0) * (details.returnQty ?? 0)) - ((details.returnAmount ?? 0)));
            }
          }
        }
      }
      return totalReturnDiscount;
    }

    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.text(printTransactionModel.personalInformationModel.companyName ?? '',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    bytes += generator.text('Seller :${printTransactionModel.transitionModel!.user?.name}', styles: const PosStyles(align: PosAlign.center));
    if (printTransactionModel.personalInformationModel.address != null) {
      bytes += generator.text(printTransactionModel.personalInformationModel.address ?? '', styles: const PosStyles(align: PosAlign.center));
    }
    if (printTransactionModel.personalInformationModel.vatNumber != null) {
      bytes += generator.text("${printTransactionModel.personalInformationModel.vatName ?? 'VAT No :'}${printTransactionModel.personalInformationModel.vatNumber ?? ''}",
          styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.text('Tel: ${printTransactionModel.personalInformationModel.phoneNumber ?? ''}', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    bytes += generator.text('Name: ${printTransactionModel.transitionModel?.party?.name ?? 'Guest'}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('mobile: ${printTransactionModel.transitionModel?.party?.phone ?? 'Not Provided'}', styles: const PosStyles(align: PosAlign.left));
    // bytes += generator.text('Sales By: ${printTransactionModel.transitionModel?.user?.name ?? 'Not Provided'}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Invoice: ${printTransactionModel.transitionModel?.invoiceNumber ?? 'Not Provided'}', styles: const PosStyles(align: PosAlign.left), linesAfter: 1);

    bytes += generator.row([
      PosColumn(text: 'Item', width: 5, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'Price', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'Amount', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr();
    List.generate(productList?.length ?? 1, (index) {
      return bytes += generator.row([
        PosColumn(
            text: productList?[index].product?.productName ?? '',
            width: 5,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: '${productList?[index].price}',
            width: 2,
            styles: const PosStyles(
              align: PosAlign.center,
            )),
        PosColumn(text: getProductQuantity(detailsId: productList?[index].id ?? 0).toString(), width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            text: "${(productList?[index].price ?? 0) * getProductQuantity(detailsId: productList?[index].id ?? 0)}", width: 3, styles: const PosStyles(align: PosAlign.right)),
      ]);
    });
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: 'Subtotal',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: '${getTotalForOldInvoice()}',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: printTransactionModel.transitionModel?.vat?.name ?? 'VAT',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: '${printTransactionModel.transitionModel?.vatAmount ?? 0}',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Discount',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: ((printTransactionModel.transitionModel?.discountAmount ?? 0) + getReturndDiscountAmount()).toStringAsFixed(2),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Total',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: ((printTransactionModel.transitionModel?.totalAmount ?? 0) + getTotalReturndAmount()).toStringAsFixed(2),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);

    ///_____Return_table_______________________________
    if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
      List.generate(printTransactionModel.transitionModel?.salesReturns?.length ?? 0, (i) {
        bytes += generator.hr();
        if (!returnedDates.any((element) =>
            element.isAtSameMomentAs(DateTime.tryParse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate?.substring(0, 10) ?? '') ?? DateTime.now()))) {
          bytes += generator.row([
            PosColumn(
                text: 'Return-${DateFormat.yMd().format(DateTime.parse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate ?? DateTime.now().toString()))}',
                width: 7,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
            PosColumn(text: 'Total', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          bytes += generator.hr();
        }

        List.generate(printTransactionModel.transitionModel?.salesReturns?[i].salesReturnDetails?.length ?? 0, (index) {
          returnedDates.add(DateTime.tryParse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate?.substring(0, 10) ?? '') ?? DateTime.now());
          final product = printTransactionModel.transitionModel?.salesReturns?[i].salesReturnDetails?[index];
          return bytes += generator.row([
            PosColumn(text: productName(detailsId: product?.saleDetailId ?? 0), width: 7, styles: const PosStyles(align: PosAlign.left)),
            PosColumn(text: product?.returnQty.toString() ?? 'Not Defined', width: 2, styles: const PosStyles(align: PosAlign.center)),
            PosColumn(text: "${(product?.returnAmount ?? 0)}", width: 3, styles: const PosStyles(align: PosAlign.right)),
          ]);
        });
        //
      });
    }
    bytes += generator.hr();

    ///_____Total Returned Amount_______________________________
    if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
      bytes += generator.row([
        PosColumn(
            text: 'Returned Amount',
            width: 8,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: '${getTotalReturndAmount()}',
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            )),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'Total Payable', width: 8, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: printTransactionModel.transitionModel?.totalAmount.toString() ?? '', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Payment Type',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: printTransactionModel.transitionModel?.paymentType?.name ?? 'N/A',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Paid Amount',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: '${printTransactionModel.transitionModel!.totalAmount!.toDouble() - printTransactionModel.transitionModel!.dueAmount!.toDouble()}',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Due Amount',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: printTransactionModel.transitionModel!.dueAmount.toString(),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.hr(ch: '=', linesAfter: 1);

    // ticket.feed(2);
    bytes += generator.text('Thank you!', styles: const PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.text(printTransactionModel.transitionModel!.saleDate ?? '', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);

    bytes += generator.text('Note: Goods once sold will not be taken back or exchanged.', styles: const PosStyles(align: PosAlign.center, bold: false), linesAfter: 1);

    bytes += generator.qrcode(
      companyWebsite,
    );
    bytes += generator.text('Developed By: $companyName', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    bytes += generator.cut();
    return bytes;
  }
}
