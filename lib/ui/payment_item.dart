import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vhks/utility/function_support.dart';

final FunctionSupport _support = FunctionSupport();

class PaymentItem extends StatelessWidget {
    const PaymentItem({super.key});

    @override
  Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),

                    const SizedBox(height: 10),

                    // QR code
                    Image.asset(
                        "assets/qr.png",
                        width: 200,
                        height: 200,
                    ),

                    const Text(
                        "[Quét mã QR để thanh toán]",
                        style: TextStyle(fontSize: 16.0, color: Colors.blueAccent),
                    ),

                    const Divider(color: Colors.black38, thickness: 0.5),

                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start, // Căn hàng đầu
                        children: [
                            Align(
                                alignment: Alignment.topLeft, // Căn top
                                child: Text(
                                    "Chủ TK:",
                                    style: TextStyle(fontSize: 13.0),
                                ),
                            ),
                            Expanded(
                                child: Text(
                                    "Công ty TNHH Công nghệ SmartRF Việt Nam",
                                    style: TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: true,
                                    textAlign: TextAlign.end
                                ),
                            ),
                        ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(
                                "Số tài khoản:",
                                style: TextStyle(fontSize: 13.0),
                            ),
                            Spacer(), // Đẩy phần bên phải về cuối hàng
                            Row( // Số tài khoản và icon sao chép
                                children: [
                                    GestureDetector(
                                        onTap: (){
                                            Clipboard.setData(ClipboardData(text: "0491000026329"));
                                            _support.showSnackbar(context, "Đã sao chép số tài khoản!", Colors.blueAccent);
                                        },
                                      child: Text(
                                          "0491000026329",
                                          style: TextStyle(
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                          ),
                                      ),
                                    ),
                                    SizedBox(width: 8), // Khoảng cách giữa số và icon
                                    GestureDetector(
                                        onTap: () {
                                            Clipboard.setData(ClipboardData(text: "0491000026329"));
                                            _support.showSnackbar(context, "Đã sao chép số tài khoản!", Colors.blueAccent);
                                        },
                                        child: Icon(Icons.copy, size: 18, color: Colors.blue),
                                    ),
                                ],
                            ),
                        ],
                    ),

                    const SizedBox(height: 5),

                    Align(
                        alignment: Alignment.centerLeft,
                      child: Text(
                          "Ngân hàng Vietcombank - CN Thăng Long Hà Nội",
                          style: TextStyle(fontSize: 13.0),
                      ),
                    ),
                ],
            ),
        );
  }
}