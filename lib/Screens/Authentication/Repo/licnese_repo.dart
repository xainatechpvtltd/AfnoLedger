import 'package:http/http.dart' as http;

import '../../../constant.dart';

class PurchaseModel {
  Future<bool> isActiveBuyer() async {
    final response =
        await http.get(Uri.parse('https://sangam69.com.np'), headers: {'Authorization': 'Bearer orZoxiU81Ok7kxsE0FvfraaO0vDW5tiz'});

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
