import 'package:flutter/material.dart';
import 'package:vhks/models/fee_info.dart';

import '../utility/function_support.dart';

final FunctionSupport _support = FunctionSupport();

class FeeItem extends StatelessWidget{
    final FeeInfo feeInfo;
    final Function(FeeInfo) onTap;

    const FeeItem({
        Key? key,
        required this.feeInfo,
        required this.onTap,
    }) : super(key: key);

  @override
  Widget build(BuildContext context) {
      return RepaintBoundary(
          child: InkWell(
              onTap: (){
                  onTap(feeInfo);
              },
              child: Container(
                  width: double.maxFinite,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: (feeInfo.feeResponse.status == "KÍCH HOẠT") ? Colors.greenAccent.shade100
                          : (feeInfo.feeResponse.status == "TẠM DỪNG") ? Colors.orangeAccent.shade100
                          : (feeInfo.feeResponse.status == "DỪNG DỊCH VỤ") ? Colors.redAccent.shade100
                          : Colors.black12,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                          Text(
                              'Tàu ${feeInfo.shipNumber}',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                              ),
                          ),

                          Container(
                              margin: EdgeInsets.only(bottom: 10),
                              child: const Divider(
                                  color: Colors.black38,
                                  thickness: 0.5,
                              ),
                          ),

                          // Trang thai kich hoat
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Text(
                                      'Trạng thái',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                      ),
                                  ),
                                  Text(
                                      feeInfo.feeResponse.status != null && feeInfo.feeResponse.status.isNotEmpty ? feeInfo.feeResponse.status : "",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: (feeInfo.feeResponse.status == "KÍCH HOẠT") ? Colors.green.shade500
                                              : (feeInfo.feeResponse.status == "TẠM DỪNG") ? Colors.orange.shade900
                                              : (feeInfo.feeResponse.status == "DỪNG DỊCH VỤ") ? Colors.white
                                              : Colors.black54,
                                      ),
                                  ),
                              ],
                          ),
                          const SizedBox(height: 5,),

                          // Gói cước
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Text(
                                      'Gói cước',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                      ),
                                  ),
                                  Text(
                                       feeInfo.feeResponse.status == "DỪNG DỊCH VỤ" ? "Không" : feeInfo.feeResponse.plan,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                      ),
                                  ),
                              ],
                          ),
                          const SizedBox(height: 5,),

                          // Ngay nop cuoc
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Text(
                                      'Ngày nộp cước',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                      ),
                                  ),
                                  Text(
                                      _support.formatFeeTime(feeInfo.feeResponse.paymentDate),
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                      ),
                                  ),
                              ],
                          ),
                          const SizedBox(height: 5,),

                          // Ngay het han
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Text(
                                      'Ngày hết cước',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                      ),
                                  ),
                                  Text(
                                      _support.formatFeeTime(feeInfo.feeResponse.expireDate),
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                      ),
                                  ),
                              ],
                          ),
                          const SizedBox(height: 5,),

                          // Cuoc tin nhan
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Text(
                                      'Cước tin nhắn',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                      ),
                                  ),
                                  Text(
                                      "${_support.formatMoney(feeInfo.feeResponse.messageCost)} VNĐ",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                      ),
                                  ),
                              ],
                          ),
                      ],
                  )
              ),
          ),
      );
  }

}