import 'package:flutter/material.dart';
import 'package:vhks/models/gps_log_info.dart';
import 'package:vhks/utility/function_support.dart';

import 'gps_log_item.dart';

class ListGpsScreen extends StatefulWidget {
  final List<GpsLogInfo> listGpsLog;

  const ListGpsScreen({Key? key, required this.listGpsLog}) : super(key: key);

  @override
  State<ListGpsScreen> createState() => _ListGpsScreenState();
}

class _ListGpsScreenState extends State<ListGpsScreen> {
  late FunctionSupport _support;
  String startDate = "";
  String endDate = "";

  @override
  void initState() {
    _support = FunctionSupport();
    final firstGps = widget.listGpsLog.firstOrNull;
    final lastGps = widget.listGpsLog.lastOrNull;
    if (firstGps != null && lastGps != null) {
      if (firstGps.byteCount == 10 && lastGps.byteCount == 10 ||
          firstGps.byteCount == 15 && lastGps.byteCount == 15) {
        startDate = _support.format10And15GpsDateTime(lastGps.gpsResponse.time);
        endDate = _support.format10And15GpsDateTime(firstGps.gpsResponse.time);
      } else if (firstGps.byteCount == 23 && lastGps.byteCount == 23) {
        startDate = _support.format23BytesDateTime(lastGps.sessionTime);
        endDate = _support.format23BytesDateTime(firstGps.sessionTime);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thanh kéo modal
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "Nhật ký hành trình",
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600),
              ),
              const Divider(color: Colors.black38, thickness: 0.5),
              Text(
                "Số lượng bản tin: ${widget.listGpsLog.length}",
                style: const TextStyle(
                    fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                "Từ: ${startDate} | Đến: ${endDate}",
                style: const TextStyle(
                    fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Danh sách bản tin GPS
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  cacheExtent: 200,
                  itemCount: widget.listGpsLog.length,
                  itemBuilder: (context, index) {
                    final gpsLog = widget.listGpsLog[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5),
                      child: GpsLogItem(
                        key: ValueKey(gpsLog.sessionTime),
                        listGpsLogs: widget.listGpsLog,
                        index: index,
                        gpsLogInfo: gpsLog,
                        onTap: () {
                          Navigator.pop(context, gpsLog);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Nút đóng modal
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.grey),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
                child: const Text(
                  "Đóng",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
