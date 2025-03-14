import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhks/api/response/ShipResponse.dart';
import 'package:vhks/database/ShipInfoDB.dart';
import 'package:vhks/ui/fee_screen.dart';

import '../api/response/LoginResponse.dart';
import '../api/response/token_response.dart';
import '../models/gps_log_info.dart';
import '../utility/constants.dart';
import '../utility/function_support.dart';
import 'colors.dart';

class ProfileScreen extends StatefulWidget {
  final List<LoginResponse> ships;
  final TokenResponse tokenResponse;

  const ProfileScreen(
      {Key? key, required this.ships, required this.tokenResponse})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<GpsLogInfo> listGpsLog = []; // Danh sach ban ghi gps

  final String TAG = "ProfileScreen";

  bool _isLoading = false;
  List<ShipResponse> shipInfoList = [];
  List<String> listShipNumber = [];
  List<String> listCaptain = [];
  Future<List<ShipResponse>>? futureShipInfo;
  late ShipInfoDB shipInfoDB;
  FunctionSupport _support = FunctionSupport();
  String? owner;
  String? phone;

  @override
  void initState() {
    shipInfoDB = ShipInfoDB();


    // Lay thong tin chu tau va so dien thoai
    _loadShipInfo();

    // Lay danh sach ten tau va thuyen truong tu database
    _getShipData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      backgroundColor: Colors.grey[300],
                      color: Colors.blue,
                      strokeWidth: 3.0,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Đang lấy dữ liệu...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                        width: double.infinity,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 20),
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
                                  color: Colors.white),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: const Divider(
                                color: Colors.white,
                                thickness: 1,
                              ),
                            ),
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
                                  listShipNumber.isNotEmpty
                                      ? (listShipNumber.length > 2
                                          ? listShipNumber
                                                  .take(2)
                                                  .map((shipNumber) =>
                                                      shipNumber.toString())
                                                  .join('\n') +
                                              '\n...+${listShipNumber.length - 2}'
                                          : listShipNumber
                                              .map((shipNumber) =>
                                                  shipNumber.toString())
                                              .join('\n'))
                                      : "",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: const Divider(
                                color: Colors.white,
                                thickness: 1,
                              ),
                            ),
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
                                  owner != null ? owner! : '',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: const Divider(
                                color: Colors.white,
                                thickness: 1,
                              ),
                            ),
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
                                  listCaptain.isNotEmpty
                                      ? (listCaptain.length > 2
                                          ? listCaptain
                                                  .take(2)
                                                  .map((shipNumber) =>
                                                      shipNumber.toString())
                                                  .join('\n') +
                                              '\n...+${listCaptain.length - 2}'
                                          : listCaptain
                                              .map((shipNumber) =>
                                                  shipNumber.toString())
                                              .join('\n'))
                                      : "",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: const Divider(
                                color: Colors.white,
                                thickness: 1,
                              ),
                            ),
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
                                  phone != null ? phone! : '',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          ],
                        )),

                    const SizedBox(
                      height: 10,
                    ),

                    // Thong tin cuoc
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeeScreen(
                              ships: widget.ships,
                              tokenResponse: widget.tokenResponse,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.blur_black,
                            borderRadius: BorderRadius.circular(20),
                            ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Thông tin cước phí',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Image.asset(
                              'assets/fee.png',
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // Thanh toan tien cuoc
                    InkWell(
                      onTap: () {
                        _support.showPaymentDialog(context);
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.blur_black,
                            borderRadius: BorderRadius.circular(15),),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Thanh toán cước phí',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Image.asset(
                              'assets/payment.png',
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // Lien he
                    InkWell(
                      onTap: () {
                        _support.showAboutDialog(context);
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.blur_black,
                            borderRadius: BorderRadius.circular(15),),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Thông tin liên hệ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Image.asset(
                              'assets/support.png',
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // Dang xuat tai khoan
                    InkWell(
                      onTap: () {
                        _support.showLogoutDialog(context);
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.blur_black,
                            borderRadius: BorderRadius.circular(15),),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đăng xuất tài khoản',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Image.asset(
                              'assets/logout.png',
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Lay du lieu tu database
  Future<void> _getShipData() async {
    _isLoading = true;
    setState(() {});

    listShipNumber = await shipInfoDB.getAllShipNumbers();
    listCaptain = await shipInfoDB.getAllCaptains();

    _isLoading = false;
    setState(() {});
  }

  // Lay thong tin chu tau va so dien thoai da luu
  Future<void> _loadShipInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      owner = prefs.getString(Constants.OWNER) ?? "";
      phone = prefs.getString(Constants.PHONE) ?? "";
    });
  }
}
