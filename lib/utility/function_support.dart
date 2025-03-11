import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vhks/api/response/LoginResponse.dart';
import 'package:vhks/api/response/token_response.dart';
import 'package:vhks/ui/fee_history_screen.dart';
import 'package:vhks/ui/payment_item.dart';
import 'package:vhks/ui/select_ship_item.dart';

import '../screens/login_screen.dart';
import '../ui/colors.dart';

class FunctionSupport {
  final String TAG = 'FunctionSupport';

  // Dinh dang so imei
  String formatImei(String input) {
    return input.length > 15 ? input.substring(1, 16) : input;
  }

  // Chuyen toa do sang don vi do
  String convertToDMS(double decimalDegree, bool isLatitude) {
    int degree = decimalDegree.toInt();
    int minute = ((decimalDegree - degree) * 60).toInt();
    int second = ((decimalDegree - degree - minute / 60.0) * 3600).toInt();

    String direction;
    if (isLatitude) {
      direction = degree > 0 ? 'N' : 'S';
    } else {
      direction = degree > 0 ? 'E' : 'W';
    }

    return "${degree.abs()}°${minute.abs().toString().padLeft(2, '0')}'${second.abs().toString().padLeft(2, '0')}''$direction";
  }

  // Tính khoảng cách giữa 2 điểm
  double distanceBetween(LatLng point1, LatLng point2) {
    const double R = 6371e3; // Bán kính Trái Đất tính bằng mét
    final double phi1 = point1.latitude * pi / 180;
    final double phi2 = point2.latitude * pi / 180;
    final double deltaPhi = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLambda = (point2.longitude - point1.longitude) * pi / 180;

    final double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Khoảng cách tính bằng mét
  }

  // Tính khoảng cách từ một điểm tới một đoạn thẳng
  double distanceToSegment(LatLng point, LatLng a, LatLng b) {
    final LatLng AP =
        LatLng(point.latitude - a.latitude, point.longitude - a.longitude);
    final LatLng AB =
        LatLng(b.latitude - a.latitude, b.longitude - a.longitude);

    final double ab2 = AB.latitude * AB.latitude + AB.longitude * AB.longitude;
    final double ap_ab =
        AP.latitude * AB.latitude + AP.longitude * AB.longitude;

    double t = ap_ab / ab2;
    t = max(0.0, min(1.0, t));

    final LatLng nearest = LatLng(
      a.latitude + AB.latitude * t,
      a.longitude + AB.longitude * t,
    );

    return distanceBetween(point, nearest);
  }

  // Tính khoảng cách ngắn nhất từ một điểm tới đường line
  double shortestDistance(LatLng point, List<LatLng> line) {
    const double METER_TO_NAUTICAL_MILE = 1.0 / 1852.0;
    double minDistance = double.maxFinite;

    for (int i = 0; i < line.length - 1; i++) {
      final double dist = distanceToSegment(point, line[i], line[i + 1]);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    final double distance = minDistance * METER_TO_NAUTICAL_MILE;
    return (distance * 10).round() / 10.0;
  }

  // Kiểm tra điểm x, y có nằm trong polygon không?
  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersections = 0;
    int count = polygon.length;

    for (int i = 0; i < count; i++) {
      LatLng p1 = polygon[i];
      LatLng p2 = polygon[(i + 1) % count];

      // Kiểm tra nếu đường ray từ 'point' cắt qua cạnh (p1, p2)
      if ((p1.longitude > point.longitude) !=
          (p2.longitude > point.longitude)) {
        double xIntersection = (p2.latitude - p1.latitude) *
                (point.longitude - p1.longitude) /
                (p2.longitude - p1.longitude) +
            p1.latitude;

        if (point.latitude < xIntersection) {
          intersections++;
        }
      }
    }

    // Nếu số giao điểm là số lẻ => Điểm nằm trong polygon, ngược lại thì nằm ngoài
    return (intersections % 2 == 1);
  }

  // Canh bao
  Future<void> showWarningDialog(
      BuildContext context, String content, String imgAssets) async {
    // Khởi tạo AudioPlayer để phát âm thanh
    final AudioPlayer audioPlayer = AudioPlayer();

    // Phát âm thanh khi dialog được hiển thị
    await audioPlayer.play(AssetSource('warning_sound.mp3'));

    // Hiển thị Dialog và chờ cho đến khi dialog đóng lại
    await showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              "Cảnh báo",
              style: TextStyle(
                  fontSize: 22.0,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(content, style: const TextStyle(fontSize: 16.0)),
              Image.asset(
                imgAssets,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          // Căn giữa các action
          actions: [
            TextButton(
              onPressed: () {
                audioPlayer.stop();
                Navigator.pop(context);
              },
              child: Text(
                "Đóng",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(Colors.grey),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    // Dừng âm thanh khi dialog bị đóng
    await audioPlayer.stop();
  }

  // Dialog about
  void showAboutDialog(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
        ),
        builder: (BuildContext context) {
          return Wrap(
            children: [
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 15.0),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15.0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2)
                    ]),
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
                    Center(
                      child: Text("Thông tin liên hệ",
                          style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Divider(color: Colors.black38, thickness: 0.5),
                    Image.asset(
                      'assets/logo.png',
                      width: 60,
                      height: 60,
                    ),
                    const Text(
                      "Công ty TNHH Công Nghệ SmartRF Việt Nam",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const Text(
                      "Địa chỉ:  Tầng 9, Tòa 3D Center, Số 3 Phố Duy Tân, Cầu Giấy, Hà Nội",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.normal),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Số điện thoại liên hệ:",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.normal),
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "- Hỗ trợ thu cước:",
                          style: TextStyle(
                              fontSize: 14.0, fontWeight: FontWeight.normal),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            _makePhoneCall("0981 037 090");
                          },
                          child: Text(
                            "0981 037 090",
                            style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blueAccent,
                                // Màu gạch chân
                                color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "- Hỗ trợ kỹ thuật:",
                          style: TextStyle(fontSize: 14.0),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            _makePhoneCall("0962 536 069");
                          },
                          child: Text(
                            "0962 536 069",
                            style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blueAccent,
                                // Màu gạch chân
                                color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  // Dialog select ship
  void showSelectShipDialog(BuildContext outerContext, String title,
      List<LoginResponse> ships, Function(LoginResponse) onTap) {
    showModalBottomSheet(
        context: outerContext,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
        ),
        builder: (BuildContext context) {
          return ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(15.0)),
            child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 10.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(15.0)),
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
                    Text(title,
                        style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(
                      height: 10,
                    ),
                    // List ship
                    Flexible(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        cacheExtent: 200,
                        itemCount: ships.length,
                        itemBuilder: (context, index) {
                          final ship = ships[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: SelectShipItem(
                              shipNumber: ship.shipName,
                              onTap: () {
                                Navigator.pop(context);
                                Future.delayed(Duration(milliseconds: 200), () {
                                  onTap(ship);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )),
          );
        });
  }

  // Dialog thong tin cuoc phi
  void showSelectFeeDialog(BuildContext outerContext, String shipNumber,
      String shipId, String status, TokenResponse tokenResponse) {
    showModalBottomSheet(
        context: outerContext,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
        ),
        builder: (BuildContext builderContext) {
          return Wrap(
            children: [
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 10.0),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15.0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2)
                    ]),
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
                    Text(
                      "Tàu $shipNumber",
                      style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "Chọn chức năng",
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 15),
                      child: const Divider(
                        color: Colors.black38,
                        thickness: 0.5,
                      ),
                    ),
                    status == "KÍCH HOẠT"
                        ? buildSelectFee(
                            title: 'Thanh toán tiền cước',
                            imagePath: 'assets/payment.png',
                            color: Colors.greenAccent.shade100,
                            onTap: () => Navigator.pop(builderContext),
                          )
                        : status == "TẠM DỪNG"
                            ? buildSelectFee(
                                title: 'Tàu đang tạm dừng dịch vụ',
                                imagePath: 'assets/suspend.png',
                                color: Colors.orangeAccent.shade100,
                                onTap: () {
                                  showSnackbar(
                                      outerContext,
                                      "Vui lòng liên hệ với tổng đài để tiếp tục sử dụng dịch vụ",
                                      Colors.orangeAccent.shade100);
                                  Navigator.pop(builderContext);
                                },
                              )
                            : status == "DỪNG DỊCH VỤ"
                                ? buildSelectFee(
                                    title: 'Tàu đã dừng dịch vụ',
                                    imagePath: 'assets/deactive.png',
                                    color: Colors.redAccent.shade100,
                                    onTap: () {
                                      showSnackbar(
                                          outerContext,
                                          "Vui lòng liên hệ với tổng đài để kích hoạt lại dịch vụ",
                                          Colors.redAccent.shade100);
                                      Navigator.pop(builderContext);
                                    },
                                  )
                                : SizedBox.shrink(),
                    SizedBox(height: 10),
                    buildSelectFee(
                      title: 'Xem lịch sử giao dịch',
                      imagePath: 'assets/feehistory.png',
                      color: Colors.blueAccent.shade100,
                      onTap: () {
                        Navigator.of(outerContext, rootNavigator: true).pop();
                        Future.delayed(Duration(milliseconds: 200), () {
                          navigateToScreen(
                              outerContext,
                              FeeHistoryScreen(
                                  shipNumber: shipNumber,
                                  shipId: shipId,
                                  tokenResponse: tokenResponse));
                        });
                      },
                    ),
                  ],
                ),
              )
            ],
          );
        });
  }

  // Hàm tái sử dụng để tạo mỗi mục chọn trong fee dialog
  Widget buildSelectFee(
      {required String title,
      required String imagePath,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: 50,
              height: 50,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog thanh toan cuoc
  void showPaymentDialog(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
        ),
        builder: (BuildContext builderContext) {
          return Wrap(
            children: [
              PaymentItem(),
            ],
          );
        });
  }

  // Dang xuat tai khoan
  void showLogoutDialog(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
        ),
        builder: (BuildContext builderContext) {
          return Wrap(
            children: [
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 15.0),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15.0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2)
                    ]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    Center(
                      child: Text(
                        "Bạn có muốn đăng xuất tài khoản này?",
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nút "Có"
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "Có",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _clearAllPreferences(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Nút "Không"
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blur_black,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "Không",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  // Dang xuat tai khoan
  Future<void> _clearAllPreferences(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("$TAG - Đã xóa toàn bộ dữ liệu SharedPreferences");
    navigateAndFinish(context, LoginScreen());
  }

  // Thong bao snackbar
  void showSnackbar(
      BuildContext context, String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );

    // Chèn OverlayEntry vào Overlay
    overlay.insert(overlayEntry);

    // Loại bỏ OverlayEntry sau khi 1 giây hiển thị
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  // Thay doi kich thuoc anh
  Future<Uint8List> resizeImage(String path, int targetWidth) async {
    // Load ảnh từ asset
    ByteData data = await rootBundle.load(path);
    Uint8List bytes = data.buffer.asUint8List();

    // Decode ảnh
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception("Không thể decode ảnh");

    // Resize ảnh
    img.Image resized = img.copyResize(image, width: targetWidth);

    // Encode lại ảnh thành PNG
    return Uint8List.fromList(img.encodePng(resized));
  }

  // Kiem tra trang thai tau
  bool isDisConnected(String dateTime) {
    try {
      // Định dạng chuỗi thời gian
      final formatter = DateFormat("dd/MM/yyyy HH:mm:ss");

      // Chuyển chuỗi thành đối tượng DateTime
      final date = formatter.parse(dateTime);

      // Lấy thời gian hiện tại
      final currentTime = DateTime.now();

      // Tính khoảng cách thời gian giữa thời gian hiện tại và chuỗi thời gian
      final duration = currentTime.difference(date).inMilliseconds;

      // Kiểm tra nếu khoảng cách thời gian >= 4 tiếng
      return duration >= 4 * 60 * 60 * 1000;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Dinh dang thoi gian
  String formatDateTime(String inputTime) {
    try {
      DateTime dateTime = DateTime.parse(inputTime).add(Duration(hours: 7));
      return DateFormat("dd/MM/yyyy HH:mm").format(dateTime);
    } catch (e) {
      print("Lỗi định dạng thời gian: $e");
      return "";
    }
  }

  // Dinh dang thoi gian gps
  String format10And15GpsDateTime(String inputTime) {
    try {
      DateTime dateTime = DateTime.parse(inputTime).add(Duration(hours: 7));
      return DateFormat("dd/MM HH:mm").format(dateTime);
    } catch (e) {
      print("Lỗi định dạng thời gian: $e");
      return "";
    }
  }

  String format23BytesDateTime(String input) {
    DateFormat inputFormat = DateFormat("MM/dd/yyyy, HH:mm:ss");
    DateTime dateTime = inputFormat.parse(input);
    DateFormat outputFormat = DateFormat("dd/MM HH:mm");
    return outputFormat.format(dateTime);
  }

  // Dinh dang thoi gian dau vao cho elapsedtime
  String formatInputElapsedTime(String inputTime) {
    try {
      DateTime dateTime = DateTime.parse(inputTime).add(Duration(hours: 7));
      return DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime);
    } catch (e) {
      print("Lỗi định dạng thời gian: $e");
      return "";
    }
  }

  // Dinh dang thoi gian gui yeu cau
  String formatRequestTime(DateTime requestTime) {
    try {
      return DateFormat("yyyy-MM-ddTHH:mm:ssZ").format(requestTime.toUtc());
    } catch (e) {
      print("Lỗi định dạng thời gian: $e");
      return "";
    }
  }

  // Dinh dang thoi gian hien thi gps
  String formatTimeShow(DateTime gpsRequestTime) {
    try {
      return DateFormat("dd/MM/yyyy").format(gpsRequestTime.toLocal());
    } catch (e) {
      print("Lỗi định dạng thời gian: $e");
      return "";
    }
  }

  // Chon thoi gian
  Future<void> selectDateTime(BuildContext context, DateTime firstDate,
      Function(DateTime) onDateTimeSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: firstDate,
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final DateTime finalDateTime =
          DateTime.utc(pickedDate.year, pickedDate.month, pickedDate.day);

      onDateTimeSelected(finalDateTime);
    }
  }

  // Chuyen tu chuoi thoi gian sang datetime
  DateTime parseDateString(String dateString) {
    try {
      DateFormat dateFormat = DateFormat("dd/MM/yyyy");
      return dateFormat.parse(dateString);
    } catch (e) {
      throw FormatException(
          "Chuỗi không đúng định dạng dd/MM/yyyy: $dateString");
    }
  }

  // Tinh khoang thoi gian giua hai thoi diem
  String calculateElapsedTime(String inputDateTime) {
    DateTime parsedDateTime = DateTime.parse(inputDateTime);

    DateTime now = DateTime.now();

    Duration difference = now.difference(parsedDateTime);

    int days = difference.inDays;
    int hours = difference.inHours % 24;
    int minutes = difference.inMinutes % 60;

    String result = "";
    if (days > 0) result += "$days ngày ";
    if (hours > 0) result += "$hours giờ ";
    if (minutes > 0) result += "$minutes phút";

    return result.trim();
  }

  // Tinh khoang thoi gian giua thoi diem hien tai va thoi diem nhat dinh theo phut
  int calculateTimeBetween(String inputDateTime) {
    DateTime parsedDateTime = DateTime.parse(inputDateTime);
    DateTime now = DateTime.now();
    Duration difference = now.difference(parsedDateTime);

    return difference.inMinutes;
  }

  // Tinh khoang thoi gian giua 2 thoi diem
  double calculateTimeDifference(String time1, String time2) {
    final dateFormat = DateFormat("dd/MM HH:mm");

    DateTime dateTime1 = dateFormat.parse(time1);
    DateTime dateTime2 = dateFormat.parse(time2);

    return (dateTime2.difference(dateTime1).inMinutes / 60.0).abs();
  }

  // Thiet lap mau chu cho khoang thoi gian tu ban tin gan nhat
  Color setColorElapsedTime(String inputDateTime) {
    int elapsedTime = calculateTimeBetween(inputDateTime);
    if (elapsedTime >= 240) {
      // Tren 4 gio
      return Colors.redAccent;
    } else if (210 <= elapsedTime && elapsedTime <= 240) {
      // Tu 3,5 den 4 gio
      return Colors.orangeAccent;
    } else {
      // duoi 3,5 gio
      return Colors.blueAccent;
    }
  }

  // Dinh dang so tien theo phan nghin
  String formatMoney(int number) {
    final formatter = NumberFormat('#,###', 'vi');
    return formatter.format(number).replaceAll(',', '.');
  }

  // Dinh dang thoi gian cho thong tin cuoc
  String formatFeeTime(String inputTime) {
    try {
      DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(inputTime);
      return DateFormat("dd/MM/yyyy").format(parsedDate);
    } catch (e) {
      return "";
    }
  }

  // Chuyen sang ung dung goi dien
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw "Không thể mở ứng dụng gọi điện";
    }
  }

  // Chuyen sang man hinh moi
  void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Chuyen sang man hinh moi va xoa man hinh hien tai
  void navigateAndFinish(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (Route<dynamic> route) => false, // Xóa tất cả các màn hình trước đó
    );
  }
}
