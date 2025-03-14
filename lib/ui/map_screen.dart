import 'dart:async';
import 'dart:typed_data';

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhks/api/response/LastGpsResponse.dart';
import 'package:vhks/api/response/ShipResponse.dart';
import 'package:vhks/service/noti_service.dart';
import 'package:vhks/ui/gps_log_screen.dart';

import '../api/request/api_service.dart';
import '../api/response/LoginResponse.dart';
import '../database/ShipInfoDB.dart';
import '../utility/constants.dart';
import '../utility/function_support.dart';
import 'TrianglePainter.dart';
import 'colors.dart';

class MapScreen extends StatefulWidget {
  final List<LoginResponse> ships;

  const MapScreen({Key? key, required this.ships}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final String TAG = "MapScreen";
  bool _isMapReady = false;
  late ShipInfoDB shipInfoDB;
  late ApiService _apiService;
  late FunctionSupport _support;
  bool _isLoading = false;
  var mapVietnam = const LatLng(16.107079, 110.206230);
  final Set<Polyline> _polylines = {};
  Set<Marker> _markers = {}; // Danh sách marker

  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  MapType _currentMapType = MapType.normal; // Bắt đầu ở chế độ bản đồ thường

  String? currentShip;
  String? currentLat;
  String? currentLong;
  String currentTimeDate = "";
  String? currentElapsedTime = "";
  LatLng? currentCoordinate;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    shipInfoDB = ShipInfoDB();
    _apiService = ApiService();
    _support = FunctionSupport();
    _initializeMapRenderer();
    _addPolyline();

    for (LoginResponse ship in widget.ships) {
      fetchShipInfo(true, ship.shipName);
    }
  }

  @override
  void dispose() {
    _customInfoWindowController.googleMapController?.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      "Đang tải dữ liệu...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: mapVietnam,
                      zoom: 4.5,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _onMapCreated(controller);
                      setState(() {
                        _isMapReady = true;
                      });
                    },
                    onTap: (position) {
                      _customInfoWindowController.hideInfoWindow!();
                    },
                    onCameraMove: (position) {
                      _customInfoWindowController.onCameraMove!();
                    },
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    polylines: _polylines,
                    markers: Set<Marker>.of(_markers),
                    mapType: _currentMapType,
                  ),

                  CustomInfoWindow(
                    controller: _customInfoWindowController,
                    height: 500,
                    width: 500,
                    offset: 35,
                  ),

                  // Xem hai trinh
                  Positioned(
                    bottom: 340,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        _support.showSelectShipDialog(
                            context, "Nhật ký hành trình", widget.ships,
                            (shipData) async {
                          debugPrint(
                              "$TAG - Selected ship: ${shipData.shipName}");
                          try {
                            ShipResponse? shipResponse = await _apiService
                                .getShipInfo(shipData.shipName);
                            if (shipResponse != null) {
                              final formatImei =
                                  _support.formatImei(shipResponse.imei);
                              final owner = shipResponse.owner;
                              _support.navigateToScreen(
                                  context,
                                  GpsLogScreen(
                                      ship: shipData.shipName,
                                      imei: formatImei,
                                      owner: owner));
                            } else {
                              _support.showSnackbar(
                                  context,
                                  "Không tìm thấy thông tin tàu!",
                                  Colors.redAccent);
                            }
                          } catch (exception) {
                            print("$TAG - $exception");
                            _support.showSnackbar(
                                context,
                                "Đã có lỗi xảy ra trong quá trình lấy dữ liệu!",
                                Colors.redAccent);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          'assets/rudder.png',
                          fit: BoxFit.contain,
                          width: double.infinity,
                          color: Colors.blueAccent,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  // Load lai
                  Positioned(
                    bottom: 270,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () async {
                        for (LoginResponse ship in widget.ships) {
                          await fetchShipInfo(true, ship.shipName);
                        }
                      },
                      child: Icon(
                        Icons.refresh_sharp,
                        color: Colors.white,
                      ),
                      backgroundColor: AppColors.gray,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  // Chuyen doi che do ban do
                  Positioned(
                    bottom: 200,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        _toggleMapType();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          _currentMapType == MapType.satellite
                              ? 'assets/map.png'
                              : 'assets/satellite.png',
                          fit: BoxFit.contain,
                          width: double.infinity,
                          color: _currentMapType == MapType.satellite
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                      backgroundColor: _currentMapType == MapType.satellite
                          ? Colors.redAccent
                          : Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  // Thong tin tau hien tai
                  Positioned(
                    bottom: 10,
                    right: 15,
                    left: 15,
                    child: IntrinsicWidth(// Chiều rộng tự động theo nội dung
                      child: IntrinsicHeight(// Chiều cao tự động theo nội dung
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Số hiệu tàu",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal),
                                  ),
                                  Text(
                                    currentShip != null ? currentShip! : "",
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                child: const Divider(
                                  color: Colors.black38,
                                  thickness: 1.5,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Vĩ độ",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal),
                                  ),
                                  Text(
                                    currentLat != null ? currentLat! : "",
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                child: const Divider(
                                  color: Colors.black38,
                                  thickness: 1.5,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Kinh độ",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal),
                                  ),
                                  Text(
                                    currentLong != null ? currentLong! : "",
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                child: const Divider(
                                  color: Colors.black38,
                                  thickness: 1.5,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Kể từ bản tin gần nhất",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal),
                                  ),
                                  Text(
                                    currentElapsedTime != null
                                        ? currentElapsedTime!
                                        : "",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _support.setColorElapsedTime(currentTimeDate)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Danh sach tau
                  Positioned(
                    bottom: 200,
                    left: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        _support.showSelectShipDialog(context, "Danh sách tàu", widget.ships, (ship) async {
                          try {
                            ShipResponse? shipResponse = await _apiService.getShipInfo(ship.shipName);
                            if (shipResponse != null) {
                              // Gọi API lấy dữ liệu vị trí
                              LastGpsResponse? gpsResponse = await fetchLastGpsData(false, shipResponse);

                              if (gpsResponse != null) {
                                final LatLng coordinates = LatLng(gpsResponse.latitude, gpsResponse.longitude);
                                final String timeDate = _support.formatInputElapsedTime(gpsResponse.time);
                                final int elapsedTime = _support.calculateTimeBetween(timeDate);

                                String? shipStatus = setShipStatus(elapsedTime);
                                Color? shipColor = setShipColor(elapsedTime);

                                // Delay 500ms trước khi cập nhật UI
                                await Future.delayed(Duration(milliseconds: 300));
                                _updateCamera(coordinates, 15);
                                _showInfoWindow(shipResponse, gpsResponse, shipStatus!, shipColor!);

                                setState(() {
                                  currentShip = ship.shipName;
                                });
                              }
                            }
                          } catch (exception) {
                            print("$TAG - $exception");
                            _support.showSnackbar(context, "Đã có lỗi xảy ra trong quá trình lấy dữ liệu!", Colors.redAccent);
                          }
                        });
                      },
                      child: Icon(
                        Icons.menu_sharp,
                        color: Colors.white,
                      ),
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ));
  }

  // Khoi tao map
  void _initializeMapRenderer() {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  }

  // Khoi tao map controller
  void _onMapCreated(GoogleMapController controller) {
    _customInfoWindowController.googleMapController = controller;
    _updateCamera(mapVietnam, 4.0);
  }

  // Di chuyen camera den vi tri cu the
  Future<void> _updateCamera(LatLng coordinate, double zoomValue) async {
    try {
      if (_isMapReady && _customInfoWindowController.googleMapController != null) {
        await _customInfoWindowController.googleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: coordinate,
              zoom: zoomValue,
              tilt: 5.0, // Góc nghiêng
            ),
          ),
        );

        await Future.delayed(Duration(milliseconds: 500));
      } else {
        debugPrint('MapController is not initialized.');
      }
    } catch (e) {
      debugPrint('Error updating camera: $e');
    }
  }

  // Them danh sach toa do duong ranh gioi
  void _addPolyline() {
    const List<LatLng> coordinates = Constants.COORDINATES_LINE;

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          color: AppColors.navy,
          width: 2,
          points: coordinates,
        ),
      );
    });
  }

  // Ve markers
  Future<void> _setUpMarker(bool isFirstOrReload, ShipResponse shipResponse, LastGpsResponse response) async {
    int retryCount = 0;
    while (!_isMapReady && retryCount < 50) {
      // Giới hạn tối đa 5 giây (50 * 100ms)
      await Future.delayed(Duration(milliseconds: 100));
      retryCount++;
    }

    if (!_isMapReady) {
      debugPrint("$TAG - Map vẫn chưa sẵn sàng sau 5 giây, hủy vẽ marker");
      return;
    }

    debugPrint("🟢 Map đã sẵn sàng, bắt đầu vẽ marker cho tàu: ${shipResponse.shipNumber}");

    LatLng coordinates = LatLng(response.latitude, response.longitude);
    String timeDate = _support.formatInputElapsedTime(response.time);
    int elapsedTime = _support.calculateTimeBetween(timeDate);

    Uint8List resizedImage;
    String? shipStatus = setShipStatus(elapsedTime);
    Color? shipColor = setShipColor(elapsedTime);

    if (elapsedTime >= 240) {
      resizedImage = await _support.resizeImage('assets/dis_ship.png', 60);
    } else {
      resizedImage = await _support.resizeImage('assets/con_ship.png', 60);
    }

    final String markerId = "marker_${shipResponse.imei}";
    final Marker newMarker = Marker(
      markerId: MarkerId(markerId),
      position: coordinates,
      icon: BitmapDescriptor.fromBytes(resizedImage),
      onTap: () async {
        // Delay 500ms trước khi cập nhật UI
        await Future.delayed(Duration(milliseconds: 500));
        if (!mounted) return; // 🔹 Kiểm tra trước khi gọi hàm cập nhật UI
        _updateCamera(coordinates, 15);
        _showInfoWindow(shipResponse, response, shipStatus!, shipColor!);

        setState(() {
            currentShip = shipResponse.shipNumber;
            currentLat = _support.convertToDMS(response.latitude, true);
            currentLong = _support.convertToDMS(response.longitude, false);
            currentTimeDate = _support.formatInputElapsedTime(response.time);
            currentElapsedTime = _support.calculateElapsedTime(timeDate);
        });
      },
    );

    setState(() {
        _markers.add(newMarker);
        _markers = Set.from(_markers);
        debugPrint("📌 Tổng số markers sau khi cập nhật: ${_markers.length}");
    });

    if (isFirstOrReload && mounted) {
      // Hiển thị cảnh báo
      await showWarningAlert(context, shipResponse.shipNumber, coordinates, response);
    }
  }

  // Thiet lap trang thai cho marker
  String? setShipStatus(int elapsedTime) {
    return elapsedTime >= 240
            ? "Mất kết nối"
            : "Đang kết nối";
  }

  // Thiet lap mau cho marker
  Color? setShipColor(int elapsedTime) {
    return elapsedTime >= 240
            ? AppColors.gray
            : AppColors.green;
  }

  // Hiển thị infoWindow
  Future<void> _showInfoWindow(ShipResponse shipResponse, LastGpsResponse response, String shipStatus, Color shipColor) async {
    double latitude = response.latitude;
    double longitude = response.longitude;
    LatLng coordinates = LatLng(latitude, longitude);
    double distance = _support.shortestDistance(coordinates, Constants.COORDINATES_LINE);

    _customInfoWindowController.addInfoWindow!(
      Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            IntrinsicWidth(
              // Chiều rộng tự động theo nội dung
              child: IntrinsicHeight(
                // Chiều cao tự động theo nội dung
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 1,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(shipStatus,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: shipColor)),
                      SizedBox(height: 5),
                      _buildInfoRow("Số hiệu tàu:", shipResponse.shipNumber, Colors.black),
                      _buildInfoRow("Chủ tàu:", shipResponse.owner, Colors.black),
                      _buildInfoRow("Thuyền trưởng:", shipResponse.captain, Colors.black),
                      _buildInfoRow("Vĩ độ:", _support.convertToDMS(latitude, true), Colors.black),
                      _buildInfoRow("Kinh độ:", _support.convertToDMS(longitude, false), Colors.black),
                      _buildInfoRow("Tốc độ:", "${response.speed} hải lý/h", Colors.black),
                      _buildInfoRow("Bản tin gần nhất:", _support.formatDateTime(response.time), Colors.black),
                      _buildInfoRow("Cách ranh giới:", "${distance} hải lý", distance < 15 ? Colors.red : Colors.black),
                    ],
                  ),
                ),
              ),
            ),
            // Tam giác dưới cùng
            Positioned(
              bottom: -10,
              child: CustomPaint(
                size: Size(20, 10),
                painter: TrianglePainter(),
              ),
            ),
          ]),
      LatLng(latitude, longitude),
    );
  }

  Widget _buildInfoRow(String title, String value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 15)),
            SizedBox(
              width: 10,
            ),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        SizedBox(height: 2),
      ],
    );
  }

  // Lay thong tin tau
  Future<void> fetchShipInfo(bool isFirstOrReload, String shipNumber) async {
      if (isFirstOrReload) {
          if (mounted) {
              setState(() {
                  _isLoading = true;
              });
          }
      }

      try {
          ShipResponse? shipResponse = await _apiService.getShipInfo(shipNumber);
          if (shipResponse == null) {
              if (mounted) {
                  _support.showSnackbar(context, "Không tìm thấy thông tin tàu", Colors.redAccent);
              }
              return;
          }

          // Kiểm tra dữ liệu đã tồn tại chưa
          if(isFirstOrReload) {
              if (await shipInfoDB.isDataExist(shipResponse.imei)) {
                  debugPrint("$TAG - Dữ liệu đã tồn tại");
              } else {
                  // Lưu dữ liệu vào database
                  int? isInsert = await shipInfoDB.insertData(shipResponse: shipResponse);
                  debugPrint(isInsert == null ? "$TAG - Không thể thêm dữ liệu" : "$TAG - Thêm dữ liệu thành công");
              }
          }

          currentShip = shipResponse.shipNumber;

          // Lưu thông tin chủ tàu và số điện thoại
          _saveShipInfo(shipResponse);

          // Lấy dữ liệu vị trí của tàu
          await fetchLastGpsData(isFirstOrReload, shipResponse);
      } catch (exception) {
          print("$TAG - $exception");
          _support.showSnackbar(context, "Đã có lỗi xảy ra trong quá trình lấy dữ liệu!", Colors.redAccent);
      } finally {
          if (mounted) {
              setState(() {
                  _isLoading = false;
              });
          }
      }
  }

  // Xu ly du lieu vi tri ban tin gan nhat
  Future<LastGpsResponse?> fetchLastGpsData(bool isFirstOrReload, ShipResponse response) async {
      if (mounted && isFirstOrReload) {
          setState(() {
              _isLoading = true;
          });
      }

      try {
          LastGpsResponse? lastGpsResponse = await _apiService.getLastGpsData(response.shipNumber);

          if (lastGpsResponse == null) {
              throw Exception("Không tìm thấy dữ liệu vị trí");
          }

          if (mounted) {
              setState(() {
                  currentLat = _support.convertToDMS(lastGpsResponse.latitude, true);
                  currentLong = _support.convertToDMS(lastGpsResponse.longitude, false);
                  currentTimeDate = _support.formatInputElapsedTime(lastGpsResponse.time);
                  currentElapsedTime = _support.calculateElapsedTime(currentTimeDate);
                  _isLoading = false;
              });
          }

          _setUpMarker(isFirstOrReload, response, lastGpsResponse);

          return lastGpsResponse;
      } catch (e) {
          if (mounted) {
              setState(() {
                  _isLoading = false;
              });
          }
          _support.showSnackbar(context, "Không thể cập nhật vị trí", Colors.redAccent);
          print("Lỗi khi lấy dữ liệu: \${e.toString()}");
          return null;
      }
  }

  // Canh bao
  Future<void> showWarningAlert(BuildContext context, String shipNumber, LatLng coordinates, dynamic response) async {
    // Mất tín hiệu GPS
    int elapsedTime = _support.calculateTimeBetween(currentTimeDate);
    if (elapsedTime >= 240) {
      // Trên 4 giờ
      NotiService().showNotification(context, title: "Cảnh báo", body: "Tàu $shipNumber mất tín hiệu GPS!");

      // await _support.showWarningDialog(context, "Tàu $shipNumber\nMất tín hiệu GPS!", 'assets/no_gps.png');
    }

    // Sat ranh gioi (duoi 15 hai ly)
    double distance = _support.shortestDistance(coordinates, Constants.COORDINATES_LINE);
    if (distance <= 15) {
      NotiService().showNotification(context, title: "Cảnh báo", body: "Tàu $shipNumber sát ranh giới!");

      // await _support.showWarningDialog(context, "Tàu $shipNumber\nSát ranh giới!", 'assets/warning.png');
    }
  }

  // Hàm chuyển đổi chế độ xem bản đồ
  void _toggleMapType() {
    setState(() {
      // Chuyển đổi giữa MapType.normal và MapType.satellite
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
      String mapType =
          _currentMapType == MapType.normal ? 'bản đồ thường' : 'vệ tinh';
      _support.showSnackbar(
          context, "Đang hiển thị ở chế độ $mapType", Colors.blueAccent);
    });
  }

  // Luu thong tin chu tau va so dien thoai
  Future<void> _saveShipInfo(ShipResponse shipInfo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.OWNER, shipInfo.owner);
    await prefs.setString(Constants.PHONE, shipInfo.phone);
  }
}
