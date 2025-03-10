import 'package:vhks/api/response/LoginResponse.dart';
import 'package:vhks/api/response/fee_response.dart';

class FeeInfo{
    final String shipNumber;
    final FeeResponse feeResponse;

    FeeInfo({
        required this.shipNumber,
        required this.feeResponse,
    });
}