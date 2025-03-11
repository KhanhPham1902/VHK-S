import 'dart:typed_data';

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:vhks/models/gps_log_info.dart';
import 'package:vhks/ui/list_gps_screen.dart';

import '../api/request/api_service.dart';
import '../api/response/PayloadResponse.dart';
import '../utility/constants.dart';
import '../utility/function_support.dart';
import 'TrianglePainter.dart';
import 'colors.dart';

class GpsLogScreen extends StatefulWidget {
  final String ship;
  final String imei;
  final String owner;

  const GpsLogScreen(
      {Key? key, required this.ship, required this.imei, required this.owner})
      : super(key: key);

  @override
  State<GpsLogScreen> createState() => _GpsLogScreenState();
}

class _GpsLogScreenState extends State<GpsLogScreen> {
  late GpsLogInfo _selectedGpsLog; // Gia tri gpslog tra ve tu ListGpsScreen

  List<GpsLogInfo> listGpsLog = []; // Danh sach ban ghi gps
  static const List<LatLng> boundaryCoordinate = Constants.COORDINATES_LINE;
  final String TAG = "GpsLogScreen";
  final String LIMIT = "1000";
  late ApiService _apiService;
  late FunctionSupport _support;
  bool _isLoading = false;
  bool _isMapReady = false;
  var mapVietnam = const LatLng(16.047079, 108.206230);
  Set<Marker> _markers = {}; // Danh sách gps marker
  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  MapType _currentMapType = MapType.normal; // Bắt đầu ở chế độ bản đồ thường
  String? _endDateShow;
  String? _startDateShow;
  String? _endDateRequest;
  String? _startDateRequest;
  bool _isShowSearch = true;
  Set<Polyline> _polyLines = {};
  List<LatLng> _polylineCoordinates = []; // Danh sach toa do gps

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _support = FunctionSupport();
    _initializeMapRenderer();

    final now = DateTime.now();
    // Hien thi thoi gian tim kiem
    _endDateShow = _support.formatTimeShow(
        DateTime(now.year, now.month, now.day, 0, 0, 0)); // Ngay hien tai
    _startDateShow = _support.formatTimeShow(
        DateTime(now.year, now.month, now.day - 3, 0, 0, 0)); // 3 ngay truoc

    // Thoi gian gui yeu cau
    _startDateRequest = _support.formatRequestTime(
        DateTime.utc(now.year, now.month, now.day - 3, 0, 0, 0));
    _endDateRequest = _support.formatRequestTime(
        DateTime.utc(now.year, now.month, now.day, 23, 59, 59));
    debugPrint("$TAG - Start Date: " + _startDateRequest!);
    debugPrint("$TAG - End Date: " + _endDateRequest!);

    // Lay danh sach ban ghi du lieu gps tu API
    if (widget.imei != null && widget.imei.isNotEmpty) {
      handleListPayload(
          true, widget.imei, _startDateRequest!, _endDateRequest!);
    }
  }

  @override
  void dispose() {
    _customInfoWindowController.googleMapController?.dispose();
    super.dispose();
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
                        zoom: 5,
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
                      polylines: _polyLines,
                      markers: Set<Marker>.of(_markers),
                      mapType: _currentMapType,
                    ),

                    CustomInfoWindow(
                      controller: _customInfoWindowController,
                      height: 400,
                      width: 400,
                      offset: 35,
                    ),

                    // Thanh tim kiem
                    Positioned(
                        top: 0,
                        right: 0,
                        left: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // So hieu tau va ten chu tau
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                width: double.infinity,
                                color: AppColors.light_blue,
                                child: Column(
                                  children: [
                                    Text(
                                      widget.ship != null ? widget.ship : "",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      widget.owner != null ? widget.owner : "",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),

                              // Tim kiem
                              Container(
                                padding: EdgeInsets.all(10),
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    _isShowSearch
                                        ? Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "Ngày bắt đầu",
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                  Icon(
                                                    Icons.location_on_sharp,
                                                    color: Colors.greenAccent,
                                                  ),
                                                  Text(
                                                    "(Nhấn để chọn ngày)",
                                                    style: TextStyle(
                                                        color:
                                                            Colors.blueAccent,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ],
                                              ),

                                              // Chon ngay bat dau
                                              InkWell(
                                                onTap: () async {
                                                  await _support.selectDateTime(
                                                      context, DateTime(2000),
                                                      (pickedDateTime) {
                                                    setState(() {
                                                      _startDateShow = _support
                                                          .formatTimeShow(
                                                              pickedDateTime);
                                                      _startDateRequest = _support
                                                          .formatRequestTime(
                                                              pickedDateTime);
                                                    });
                                                    debugPrint(
                                                        "Selected start date show: $_startDateShow");
                                                    debugPrint(
                                                        "Selected start date request: $_startDateRequest");
                                                  });
                                                },
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 5),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey,
                                                        width: 1.0),
                                                    // Viền ngoài
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15.0), // Bo góc
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            _startDateShow!,
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .blueAccent,
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons
                                                              .calendar_month_outlined,
                                                          color: Colors
                                                              .greenAccent,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 5),

                                              Row(
                                                children: [
                                                  Text(
                                                    "Ngày kết thúc",
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                  Icon(
                                                    Icons.location_on_sharp,
                                                    color: Colors.redAccent,
                                                  ),
                                                  Text(
                                                    "(Nhấn để chọn ngày)",
                                                    style: TextStyle(
                                                        color:
                                                            Colors.blueAccent,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ],
                                              ),

                                              // Chon ngay ket thuc
                                              InkWell(
                                                onTap: () async {
                                                  await _support.selectDateTime(
                                                      context,
                                                      _support.parseDateString(
                                                          _startDateShow!),
                                                      (pickedDateTime) {
                                                    setState(() {
                                                      _endDateShow = _support
                                                          .formatTimeShow(
                                                              pickedDateTime);
                                                      _endDateRequest = _support
                                                          .formatRequestTime(
                                                              pickedDateTime);
                                                    });
                                                    debugPrint(
                                                        "Selected end date show: $_endDateShow");
                                                    debugPrint(
                                                        "Selected end date request: $_endDateRequest");
                                                  });
                                                },
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 5),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey,
                                                        width: 1.0),
                                                    // Viền ngoài
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15.0), // Bo góc
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            _endDateShow!,
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .blueAccent,
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons
                                                              .calendar_month_outlined,
                                                          color:
                                                              Colors.redAccent,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 10),

                                              // Nut tim kiem
                                              CupertinoButton(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16.0,
                                                      vertical: 10.0),
                                                  // Độ dày lề nút
                                                  color: Colors.blueAccent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15.0),
                                                  child: Text(
                                                    "Tìm kiếm",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    if (widget.imei != null &&
                                                        widget
                                                            .imei.isNotEmpty) {
                                                      handleListPayload(
                                                          true,
                                                          widget.imei,
                                                          _startDateRequest!,
                                                          _endDateRequest!);
                                                    }
                                                    setState(() {
                                                      _isShowSearch = false;
                                                    });
                                                  }),

                                              Container(
                                                child: const Divider(
                                                  color: Colors.black38,
                                                  thickness: 0.5,
                                                ),
                                              ),

                                              // Hien thanh tim kiem
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _isShowSearch =
                                                        !_isShowSearch;
                                                  });
                                                },
                                                child: Container(
                                                  width: double.infinity,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        "Ẩn thanh tìm kiếm",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal),
                                                      ),
                                                      Icon(
                                                        Icons
                                                            .arrow_upward_sharp,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            ],
                                          )
                                        : // An va hien thanh tim kiem
                                        InkWell(
                                            onTap: () {
                                              setState(() {
                                                _isShowSearch = !_isShowSearch;
                                              });
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Hiển thị thanh tìm kiếm",
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                  Icon(
                                                    Icons.arrow_downward,
                                                    color: Colors.blueAccent,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),

                    // Chuyen doi che do ban do
                    Positioned(
                      bottom: 190,
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
                                : Colors.blueAccent,
                          ),
                        ),
                        backgroundColor: _currentMapType == MapType.satellite
                            ? Colors.redAccent
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),

                    // Danh sach ban ghi gps
                    Positioned(
                      bottom: 120,
                      right: 20,
                      child: FloatingActionButton(
                        onPressed: () async {
                          if (listGpsLog.length > 0) {
                            await _sendAndReceiveDataFromListGpsScreen(
                                listGpsLog);
                            // Delay 500ms trước khi cập nhật UI
                            await Future.delayed(Duration(milliseconds: 500));
                            // Cập nhật UI sau khi cập nhật dữ liệu
                            setState(() {
                              _isShowSearch = false;
                              final LatLng coordinates = LatLng(
                                  _selectedGpsLog.gpsResponse.latitude,
                                  _selectedGpsLog.gpsResponse.longitude);
                              _updateCamera(coordinates, 15);
                              _showInfoWindow(_selectedGpsLog);
                            });
                          } else {
                            debugPrint("$TAG - List is empty");
                            _support.showSnackbar(
                                context,
                                "Không có dữ liệu nhật ký cho khoảng thời gian này\nVui lòng chọn khoảng thời gian khác",
                                Colors.redAccent);
                          }
                        },
                        child: Icon(
                          Icons.menu_sharp,
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),

                    // Thoat
                    Positioned(
                      bottom: 50,
                      right: 20,
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                        backgroundColor: AppColors.gray,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                )),
    );
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
    _updateCamera(mapVietnam, 5.0);
  }

  // Di chuyen camera den vi tri moi
  void _updateCamera(LatLng coordinate, double zoomValue) async {
    try {
      if (_isMapReady &&
          _customInfoWindowController.googleMapController != null) {
        await _customInfoWindowController.googleMapController?.animateCamera(
          CameraUpdate.newLatLngZoom(coordinate, zoomValue),
        );

        await Future.delayed(Duration(milliseconds: 500));
      } else {
        debugPrint('MapController is not initialized.');
      }
    } catch (e) {
      debugPrint('Error updating camera: $e');
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

  // Xu ly danh sach payload
  Future<void> handleListPayload(
      bool isLoading, String imei, String startTime, String endTime) async {
    if (isLoading) {
      _isLoading = true;
    }
    final formatImei = _support.formatImei(imei);
    try {
      listGpsLog =
          await fetchListPayload(formatImei, startTime, endTime, LIMIT);

      if (listGpsLog.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        _setUpGpsMarker(listGpsLog);
      } else {
        setState(() {
          _isLoading = false;
          _support.showSnackbar(
              context, "Không tìm thấy dữ liệu bản tin", Colors.red);
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("$TAG - Lỗi: $e");
    }
  }

  // Lay danh sach payload
  Future<List<GpsLogInfo>> fetchListPayload(
      String imei, String startDate, String endDate, String limit) async {
    try {
      List<PayloadResponse>? payloadResponse =
          await _apiService.getListPayload(imei, startDate, endDate, limit);

      if (payloadResponse != null && payloadResponse.isNotEmpty) {
        List<GpsLogInfo> result = [];

        for (PayloadResponse payloadData in payloadResponse) {
          var payload = payloadData.payload;
          var lengthData = payloadData.length;
          var time = payloadData.sessionTime;

          // Giải mã dữ liệu và thêm vào danh sách
          dynamic gpsLogResponse = await enCodePayload(payload, lengthData);

          if (gpsLogResponse != null) {
            var gpsLogInfo = GpsLogInfo(
                gpsResponse: gpsLogResponse,
                byteCount: lengthData,
                sessionTime: time);
            result.add(gpsLogInfo);
          }
        }

        return result;
      } else {
        return [];
      }
    } catch (e) {
      print("Lỗi khi lấy danh sách payload: $e");
      return [];
    }
  }

  // Giai ma payload
  Future<dynamic> enCodePayload(String payload, int length) async {
    try {
      if (length == 15 || length == 10 || length == 23) {
        return await _apiService.enCodePayload(payload, length);
      } else {
        debugPrint("$TAG - Độ dài payload không hợp lệ: $length");
      }
    } catch (e) {
      print("Lỗi khi giải mã payload: $e");
      throw Exception("Lỗi xử lý payload");
    }
  }

  // Ve markers
  Future<void> _setUpGpsMarker(List<GpsLogInfo> gpsLogs) async {
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

    // Load icon marker
    Uint8List startMarkerIcon =
        await _support.resizeImage('assets/start_locate.png', 80);
    Uint8List endMarkerIcon =
        await _support.resizeImage('assets/end_locate.png', 80);
    Uint8List defaultMarkerIcon =
        await _support.resizeImage('assets/dot.png', 40);

    setState(() {
      _polylineCoordinates.clear();
      _markers.clear(); // Xóa toàn bộ marker trước khi vẽ lại

      LatLngBounds? bounds;
      double? minLat, minLng, maxLat, maxLng;

      for (int i = 0; i < gpsLogs.length; i++) {
        final gpsLog = gpsLogs[i];
        final LatLng coordinates =
            LatLng(gpsLog.gpsResponse.latitude, gpsLog.gpsResponse.longitude);
        _polylineCoordinates.add(coordinates);

        // Xác định giới hạn LatLngBounds
        if (minLat == null || coordinates.latitude < minLat)
          minLat = coordinates.latitude;
        if (maxLat == null || coordinates.latitude > maxLat)
          maxLat = coordinates.latitude;
        if (minLng == null || coordinates.longitude < minLng)
          minLng = coordinates.longitude;
        if (maxLng == null || coordinates.longitude > maxLng)
          maxLng = coordinates.longitude;

        String markerId = "marker_$i";
        BitmapDescriptor icon;

        if (i == 0) {
          icon = BitmapDescriptor.fromBytes(endMarkerIcon); // Marker đầu tiên
        } else if (i == gpsLogs.length - 1) {
          icon =
              BitmapDescriptor.fromBytes(startMarkerIcon); // Marker cuối cùng
        } else {
          icon = BitmapDescriptor.fromBytes(defaultMarkerIcon); // Marker giữa
        }

        _markers.add(Marker(
          markerId: MarkerId(markerId),
          position: coordinates,
          icon: icon,
          onTap: () {
            _updateCamera(coordinates, 15);
            _showInfoWindow(gpsLog);
          },
        ));
      }

      // Nếu có ít nhất hai điểm, cập nhật camera để fit toàn bộ line
      if (minLat != null &&
          minLng != null &&
          maxLat != null &&
          maxLng != null) {
        bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        Future.delayed(Duration(milliseconds: 500), () async {
          GoogleMapController? controller =
              await _customInfoWindowController.googleMapController;
          if (controller != null) {
            controller
                .animateCamera(CameraUpdate.newLatLngBounds(bounds!, 100));
          }
        });
      }

      // Vẽ polyline
      _updatePolylines();
    });
  }

  // ve polyline
  void _updatePolylines() {
    setState(() {
      _polyLines.clear();

      // gps line
      _polyLines.add(Polyline(
        polylineId: PolylineId("gpsline"),
        color: Colors.red,
        width: 1,
        points: List.from(_polylineCoordinates),
      ));

      // Đường ranh giới
      _polyLines.add(Polyline(
        polylineId: PolylineId("boundary"),
        color: AppColors.navy,
        width: 2,
        points: List.from(boundaryCoordinate),
      ));
    });
  }

  // Hiển thị infoWindow
  void _showInfoWindow(GpsLogInfo gpsLogInfo) {
    double latitude = gpsLogInfo.gpsResponse.latitude;
    double longitude = gpsLogInfo.gpsResponse.longitude;
    LatLng coordinates = LatLng(latitude, longitude);
    double distance =
        _support.shortestDistance(coordinates, Constants.COORDINATES_LINE);
    bool isInside =
        _support.isPointInPolygon(coordinates, Constants.COORDINATES_LINE);

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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.ship,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent),
                      ),
                      Text(
                          (gpsLogInfo.gpsResponse.typeMessage == 1 ||
                                  gpsLogInfo.gpsResponse.typeMessage == 3)
                              ? "(Bản tin định kỳ)"
                              : (gpsLogInfo.gpsResponse.typeMessage == 0)
                                  ? "(Bản tin khởi động)"
                                  : (gpsLogInfo.gpsResponse.typeMessage == 4)
                                      ? "(Bản tin SOS)"
                                      : "(Bản tin khác)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: (gpsLogInfo.gpsResponse.typeMessage == 1 ||
                                    gpsLogInfo.gpsResponse.typeMessage == 3)
                                ? Colors.blueAccent
                                : (gpsLogInfo.gpsResponse.typeMessage == 0)
                                    ? Colors.greenAccent.shade700
                                    : (gpsLogInfo.gpsResponse.typeMessage == 4)
                                        ? Colors.red.shade700
                                        : Colors.black54,
                          )),
                      Container(
                        child: const Divider(
                          color: Colors.black38,
                          thickness: 1,
                        ),
                      ),
                      _buildInfoRow("Vĩ độ:",
                          _support.convertToDMS(latitude, true), Colors.black),
                      _buildInfoRow(
                          "Kinh độ:",
                          _support.convertToDMS(longitude, false),
                          Colors.black),
                      _buildInfoRow(
                          "Tốc độ:",
                          "${gpsLogInfo.gpsResponse.speed} hải lý/h",
                          Colors.black),
                      _buildInfoRow(
                          "Thời gian:",
                          (gpsLogInfo.byteCount == 10 ||
                                  gpsLogInfo.byteCount == 15)
                              ? _support.format10And15GpsDateTime(
                                  gpsLogInfo.gpsResponse.time)
                              : gpsLogInfo.byteCount == 23
                                  ? _support.format23BytesDateTime(
                                      gpsLogInfo.sessionTime)
                                  : "",
                          Colors.black),
                      _buildInfoRow(
                          "Cách ranh giới:",
                          "${distance} hải lý",
                          (!isInside || distance < 15)
                              ? Colors.red
                              : Colors.black),
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

  // Ve thanh phan cho infowindow
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
            Text(value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        SizedBox(height: 2),
      ],
    );
  }

  // Nhan du lieu tra ve tu ListGpsScreen
  Future<void> _sendAndReceiveDataFromListGpsScreen(
      List<GpsLogInfo> listGpsLog) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ListGpsScreen(
                listGpsLog: listGpsLog,
              )),
    );

    // Nhận dữ liệu từ Screen2 khi pop về
    if (result != null) {
      setState(() {
        _selectedGpsLog = result;
      });
    }
  }
}
