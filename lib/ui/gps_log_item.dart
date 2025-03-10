import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vhks/models/gps_log_info.dart';
import 'package:vhks/utility/function_support.dart';

import 'colors.dart';

final FunctionSupport _support = FunctionSupport();

class GpsLogItem extends StatelessWidget{
    final int index;
    final GpsLogInfo gpsLogInfo;
    final VoidCallback onTap;

    const GpsLogItem({
        Key? key,
        required this.index,
        required this.gpsLogInfo,
        required this.onTap,
    }) : super(key: key);

  @override
  Widget build(BuildContext context) {
      return RepaintBoundary(
        child: InkWell(
            onTap: (){
                onTap();
            },
            child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.blur_black,
                    borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        // Chỉ mục & Icon
                        Row(
                            children: [
                                Text(
                                    "${index + 1}",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                    ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                    Icons.location_on_sharp,
                                    color: Colors.blueAccent,
                                    size: 40,
                                ),
                            ],
                        ),

                        // Loại bản tin & thời gian
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Text(
                                    (gpsLogInfo.gpsResponse.typeMessage == 1 || gpsLogInfo.gpsResponse.typeMessage == 3) ? "Bản tin định kỳ"
                                        : (gpsLogInfo.gpsResponse.typeMessage == 0) ? "Bản tin khởi động"
                                        : (gpsLogInfo.gpsResponse.typeMessage == 4) ? "Bản tin SOS"
                                        : "Bản tin khác",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: (gpsLogInfo.gpsResponse.typeMessage == 1 || gpsLogInfo.gpsResponse.typeMessage == 3) ? Colors.blueAccent
                                            : (gpsLogInfo.gpsResponse.typeMessage == 0) ? Colors.greenAccent.shade700
                                            : (gpsLogInfo.gpsResponse.typeMessage == 4) ? Colors.red.shade700
                                            : Colors.black54,
                                    )
                                ),
                                Text(
                                    (gpsLogInfo.byteCount == 10 || gpsLogInfo.byteCount == 15) ? _support.format10And15GpsDateTime(gpsLogInfo.gpsResponse.time)
                                        : (gpsLogInfo.byteCount == 23) ? _support.format23BytesDateTime(gpsLogInfo.sessionTime)
                                        : "",
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                                ),
                            ],
                        ),

                        // Tọa độ
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    gpsLogInfo.gpsResponse.longitude != null ? _support.convertToDMS(gpsLogInfo.gpsResponse.longitude, false) : '',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                                ),
                                Text(
                                    gpsLogInfo.gpsResponse.latitude != null ? _support.convertToDMS(gpsLogInfo.gpsResponse.latitude, true) : '',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                                ),
                            ]
                        )
                    ],
                ),
            ),
        ),
      );
  }
}