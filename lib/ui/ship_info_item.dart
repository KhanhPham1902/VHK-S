import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vhks/api/response/ShipResponse.dart';

class ShipInfoItem extends StatelessWidget{
    final ShipResponse shipInfo;

    ShipInfoItem({required this.shipInfo});

    @override
    Widget build(BuildContext context){
        return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.blueAccent.shade100,
                borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Text(
                        'Thông tin tàu cá',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        ),
                    ),
                    const SizedBox(height: 15,),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(
                                'Số hiệu tàu',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                ),
                            ),
                            Text(
                                shipInfo.shipNumber,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(
                                'Chủ tàu',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                ),
                            ),
                            Text(
                                shipInfo.owner,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(
                                'Thuyền trưởng',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                ),
                            ),
                            Text(
                                shipInfo.captain,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(
                                'Số điện thoại',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                ),
                            ),
                            Text(
                                shipInfo.phone,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                ),
                            ),
                        ],
                    )
                ],
            )
        );
    }
}