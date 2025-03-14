import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhks/api/response/fee_response.dart';
import 'package:vhks/api/response/token_response.dart';
import 'package:vhks/ui/fee_item.dart';

import '../api/request/api_service.dart';
import '../api/response/LoginResponse.dart';
import '../models/fee_info.dart';
import '../utility/constants.dart';
import '../utility/function_support.dart';
import 'colors.dart';

class FeeScreen extends StatefulWidget {
    final List<LoginResponse> ships;
    final TokenResponse tokenResponse;
    const FeeScreen({Key? key, required this.ships, required this.tokenResponse}) : super(key: key);

    @override
    State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen> {

    final String TAG = "FeeScreen";
    late FunctionSupport _support;
    late ApiService _apiService;
    final Map<String, FeeResponse?> _feeData = {};
    bool _isLoading = true;

    @override
  void initState() {
        super.initState();
        _apiService = ApiService();
        _support = FunctionSupport();

        fetchFeeData();
  }

      @override
      Widget build(BuildContext context) {
          return Scaffold(
              // Thong tin cuoc
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
                            'Thông tin cước phí',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                      ),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _feeData == null || _feeData.isEmpty || _feeData.values.every((value) => value == null)
                        ? const Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orangeAccent),
                                    SizedBox(height: 10),
                                    Text("Không có dữ liệu cước phí", style: TextStyle(fontSize: 16)),
                                ],
                            ),
                        )

                        : Expanded(
                          child: Column(
                              children: [
                                  // Thong tin so du va so no
                                  Container(
                                      width: double.maxFinite,
                                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: Colors.blueAccent.shade100,
                                          borderRadius: BorderRadius.circular(15),
                                          boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 5,
                                                  spreadRadius: 2
                                              )
                                          ]
                                      ),
                                      child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                              // So du
                                              Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                      Text(
                                                          'Số dư cước',
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.normal,
                                                          ),
                                                      ),
                                                      Text(
                                                          (_feeData[widget.ships.first.shipId]!.balance > 0)
                                                              ? "${_support.formatMoney(_feeData[widget.ships.first.shipId]!.balance)} VNĐ"
                                                              : "0 VNĐ",
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                          ),
                                                      ),
                                                  ],
                                              ),
                          
                                              const SizedBox(height: 5,),
                          
                                              // So tien no
                                              Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                      Text(
                                                          'Số tiền còn nợ',
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.normal,
                                                          ),
                                                      ),
                                                      Text(
                                                          (_feeData[widget.ships.first.shipId]!.balance < 0)
                                                              ? "${_support.formatMoney(-_feeData[widget.ships.first.shipId]!.balance)} VNĐ"
                                                              : "0 VNĐ",
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                          ),
                                                      ),
                                                  ],
                                              ),
                                          ],
                                      ),
                                  ),
                          
                                  // Thong tin cuoc phi tung tau
                                  Expanded(
                                      child: ListView.separated(
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: widget.ships.length,
                                          separatorBuilder: (_, index) => const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                              final ship = widget.ships[index];
                                              final feeResponse = _feeData[ship.shipId];

                                              final feeInfo = FeeInfo(shipNumber: ship.shipName, feeResponse: feeResponse!);

                                              return FeeItem(
                                                  feeInfo: feeInfo,
                                                  onTap: (feeInfo) {
                                                      _support.showSelectFeeDialog(context, feeInfo.shipNumber, ship.shipId, feeInfo.feeResponse.status, widget.tokenResponse);
                                                  },
                                              );
                                          },
                                      ),
                                  ),

                                  const SizedBox(height: 20),
                              ],
                          ),
                        ),
                  ],
                ),
              ),
          );
      }

      // Lay thong tin cuoc
      Future<void> fetchFeeData() async {
          try {
              var token = widget.tokenResponse.token;
              if (token == null || token.isEmpty) {
                  _support.showSnackbar(context, "Chưa đăng nhập!", Colors.redAccent);
                  return;
              }

              for (var ship in widget.ships) {
                  final response = await _apiService.getFeeData(token, ship.shipId);
                  if (response != null) {
                      _feeData[ship.shipId] = response;
                  } else {
                      _feeData[ship.shipId] = null;
                  }
              }
          } catch (exception) {
              print("Lỗi lấy dữ liệu cước: $exception");
              _support.showSnackbar(context, "Đã có lỗi xảy ra khi lấy dữ liệu cước phí!", Colors.redAccent);
          }

          // Cập nhật trạng thái sau khi tải dữ liệu
          setState(() {
              _isLoading = false;
          });
      }

}