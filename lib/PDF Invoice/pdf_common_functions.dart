import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/model/sale_transaction_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../Screens/PDF/pdf.dart';

class PDFCommonFunctions {
  //-------------------image
  Future<dynamic> getNetworkImage(String imageURL) async {
    if (imageURL.isEmpty) return null;
    try {
      final Uri uri = Uri.parse(imageURL);
      final String fileExtension = uri.path.split('.').last.toLowerCase();
      if (fileExtension == 'png' || fileExtension == 'jpg' || fileExtension == 'jpeg') {
        final List<int> responseBytes = await http.readBytes(uri);
        return Uint8List.fromList(responseBytes);
      } else if (fileExtension == 'svg') {
        final response = await http.get(uri);
        return response.body;
      } else {
        print('Unsupported image type: $fileExtension');
        return null;
      }
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  Future<Uint8List?> loadAssetImage(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (e) {
      print('Error loading local image: $e');
      return null;
    }
  }

  int serialNumber = 1; // Initialize serial number
  num getProductQuantity({required num detailsId, required SalesTransactionModel transactions}) {
    num totalQuantity = transactions.salesDetails?.where((element) => element.id == detailsId).first.quantities ?? 0;
    if (transactions.salesReturns?.isNotEmpty ?? false) {
      for (var returns in transactions.salesReturns!) {
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

  static Future<void> savePdfAndShowPdf({required BuildContext context, required String shopName, required String invoice, required pw.Document doc}) async {
    if (Platform.isIOS) {
      EasyLoading.show(status: 'Generating PDF');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${'$appsName-$shopName-$invoice'}.pdf');

      final byteData = await doc.save();
      try {
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        EasyLoading.showSuccess('Done');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(path: file.path),
          ),
        );
      } on FileSystemException catch (err) {
        EasyLoading.showError(err.message);
        // handle error
      }
    }

    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.storage.request();
      }
      if (true) {
        EasyLoading.show(status: 'Generating PDF');
        const downloadsFolderPath = '/storage/emulated/0/Download/';
        Directory dir = Directory(downloadsFolderPath);
        var file = File('${dir.path}/${'$appsName-$shopName-$invoice'}.pdf');
        for (var i = 1; i < 20; i++) {
          if (await file.exists()) {
            try {
              await file.delete();
              break;
            } catch (e) {
              if (e.toString().contains('Cannot delete file')) {
                file = File('${file.path.replaceAll(RegExp(r'\(\d+\)?'), '').replaceAll('.pdf', '')}($i).pdf');
              }
            }
          } else {
            break;
          }
        }

        try {
          final byteData = await doc.save();

          await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          EasyLoading.showSuccess('Created and Saved');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerPage(path: file.path),
            ),
          );
        } on FileSystemException catch (err) {
          EasyLoading.showError(err.message);
        }
      }
    }
  }
}
