import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vhks/api/response/fee_history_response.dart';
import 'package:vhks/ui/fee_history_item.dart';

import '../api/request/api_service.dart';
import '../api/response/LoginResponse.dart';
import '../api/response/token_response.dart';
import '../utility/function_support.dart';

class FeeHistoryScreen extends StatefulWidget {
    final String shipNumber;
    final String shipId;
    final TokenResponse tokenResponse;
    const FeeHistoryScreen({Key? key, required this.shipNumber, required this.shipId, required this.tokenResponse}) : super(key: key);

    @override
    State<FeeHistoryScreen> createState() => _FeeHistoryScreen();
}

class _FeeHistoryScreen extends State<FeeHistoryScreen> {

    final String TAG = "FeeHistoryScreen";
    late FunctionSupport _support;
    late ApiService _apiService;
    List<FeeHistoryResponse> _listFeeHistory = [];

    @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _support = FunctionSupport();

    _fetchFeeHistory();
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
            body: SafeArea(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Thoat
                        InkWell(
                            onTap: (){
                                Navigator.pop(context);
                            },
                            child: Padding(
                                padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                                child: Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 30,
                                    color: Colors.black38,
                                ),
                            ),
                        ),

                        Center(
                            child: Text(
                                'Lịch sử giao dịch',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                ),
                            ),
                        ),

                        Center(
                            child: Text(
                                'Tàu ${widget.shipNumber}',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                ),
                            ),
                        ),

                        const SizedBox(height: 15,),

                        Expanded(
                            child: _listFeeHistory.isEmpty
                                ? const Center(child: Text("Không có dữ liệu giao dịch", style: TextStyle(fontSize: 16),))
                                : ListView.separated(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _listFeeHistory.length,
                                separatorBuilder: (_, index) => const SizedBox(height: 10),
                                itemBuilder: (itemContext, index) {
                                    final feeHistory = _listFeeHistory[index];
                                    return FeeHistoryItem(feeHistory: feeHistory);
                                }
                            ),
                        ),

                        const SizedBox(height: 15,),
                    ],
                )
            ),
        );
  }

  // Lay lich su giao dich
    Future<void> _fetchFeeHistory() async {
        try {
            var token = widget.tokenResponse.token;
            if (token == null || token.isEmpty) {
                _support.showSnackbar(context, "Chưa đăng nhập!", Colors.redAccent);
                return;
            }

            final response = await _apiService.getFeeHistory(token, widget.shipId);

            if (response != null) {
                setState(() {
                    _listFeeHistory = response;
                });
            } else {
                _support.showSnackbar(context, "Không tìm thấy dữ liệu giao dịch!", Colors.redAccent);
            }
        } catch (exception) {
            print("$TAG - $exception");
            _support.showSnackbar(context, "Đã có lỗi xảy ra trong quá trình lấy dữ liệu giao dịch!", Colors.redAccent);
        }
    }

}