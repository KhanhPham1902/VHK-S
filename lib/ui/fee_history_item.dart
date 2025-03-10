
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vhks/api/response/fee_history_response.dart';

import '../utility/function_support.dart';
import 'colors.dart';

final FunctionSupport _support = FunctionSupport();

class FeeHistoryItem extends StatelessWidget{
    final FeeHistoryResponse feeHistory;

    FeeHistoryItem({required this.feeHistory});

    @override
    Widget build(BuildContext context) {
        return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                  // Icon theo loai giao dich
                  Image.asset(
                      feeHistory.deposit > 0 ? "assets/bottomright.png" : "assets/topleft.png",
                      fit: BoxFit.cover,
                      width: 30,
                      height: 30,
                  ),

                  const SizedBox(width: 20,),

                  Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [

                                  // So tien giao dich
                                  Text(
                                      feeHistory.deposit > 0
                                      ? "+${_support.formatMoney(feeHistory.deposit)} đ"
                                      : feeHistory.deposit < 0
                                      ? "${_support.formatMoney(feeHistory.deposit)} đ"
                                      : "0 đ",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: feeHistory.deposit > 0
                                              ? AppColors.green
                                              : feeHistory.deposit < 0
                                              ? Colors.black54
                                              : Colors.black54,
                                      ),
                                  ),

                                  // Thoi gian giao dich
                                  Text(
                                      _support.formatDateTime(feeHistory.depositTime),
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.normal,
                                      ),
                                  ),
                              ],
                          ),

                          const SizedBox(height: 5,),

                          // So du tai khoan
                          Text(
                              "Số dư: ${_support.formatMoney(feeHistory.balance)} đ",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                              ),
                          ),

                          const SizedBox(height: 5,),

                          // Loai giao dich
                          Text(
                              feeHistory.type == "NapTien" ? "Nạp tiền cước phí"
                              : feeHistory.type == "ThanhToanGoiCuoc" ? "Thanh toán cước dịch vụ"
                              : feeHistory.type == "TamNgungGoiCuoc" ? "Tạm dừng dịch vụ"
                              : feeHistory.type == "HuyCuoc" ? "Hủy dịch vụ"
                              : feeHistory.type == "KichHoatThietBi" ? "Kích hoạt lại dịch vụ"
                              : feeHistory.type == "CuocTinNhan" ? "Thanh toán cước tin nhắn"
                              : "Khác",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                              ),
                          ),
                      ],
                                    ),
                  ),
              ],
            ),
        );
    }
}