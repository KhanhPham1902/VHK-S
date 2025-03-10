import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utility/function_support.dart';
import 'colors.dart';

class SelectShipItem extends StatefulWidget {
    final String shipNumber;
    final VoidCallback onTap;

    const SelectShipItem({
        Key? key,
        required this.shipNumber,
        required this.onTap,
    }) : super(key: key);

    @override
    _SelectShipItemState createState() => _SelectShipItemState();
}

class _SelectShipItemState extends State<SelectShipItem> {
    bool _isPressed = false;

    @override
    Widget build(BuildContext context) {
        return InkWell(
            onTapDown: (_) => setState(() => _isPressed = true),  // Khi nhấn xuống
            onTapUp: (_) => setState(() => _isPressed = false),  // Khi thả ra
            onTapCancel: () => setState(() => _isPressed = false),  // Nếu hủy nhấn
            onTap: widget.onTap,
            child: Container(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: _isPressed ? Colors.blueAccent : AppColors.blur_black, // Đổi màu khi nhấn
                    borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                Image.asset(
                                    'assets/ship.png',
                                    fit: BoxFit.contain,
                                    width: 50,
                                    height: 50,
                                ),
                                Text(
                                    widget.shipNumber,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        );
    }
}
