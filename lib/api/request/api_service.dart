import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:vhks/api/response/GpsResponse15Bytes.dart';
import 'package:vhks/api/response/LastGpsResponse.dart';
import 'package:vhks/api/response/LoginResponse.dart';
import 'package:vhks/api/response/PayloadResponse.dart';
import 'package:vhks/api/response/ShipResponse.dart';
import 'package:vhks/api/response/fee_history_response.dart';
import 'package:vhks/api/response/fee_response.dart';
import 'package:vhks/api/response/token_response.dart';
import 'package:vhks/utility/constants.dart';

import '../response/GpsResponse10Bytes.dart';
import '../response/GpsResponse23Bytes.dart';

class ApiService{
    final String gstcUrl = Constants.GSTC_URL;
    final String authKeyGSTC = Constants.authGSTCKey;
    final String vhksUrl = Constants.VHKS_URL;
    final String authKeyVHKS = Constants.authVHKSKey;
    final Duration timeOutDuration = const Duration(seconds: 10);
    final http.Client httpClient;

    final String loginUrl = Constants.loginUrl;

    final String TAG = "ApisService";

    ApiService({http.Client? client}) : httpClient = client ?? http.Client();

/// ================ GET =================================================

    // Lay thong tin vi tri gan nhat
    Future<LastGpsResponse?> getLastGpsData(String shipNumber) async {
        final url = Uri.parse('$gstcUrl/api/ship/info/$shipNumber');

        try{
            // Sử dụng retryRequest để thử lại nếu có lỗi
            var response = await retryRequest(
                maxAttempts: 3, // Số lần thử lại
                delayBetweenRetries: Duration(seconds: 2),
                block: () => httpClient.get(
                    url,
                    headers: {'Authorization': "$authKeyGSTC"},
                ).timeout(timeOutDuration),
            );

            if (response != null && response.statusCode == 200) {
                debugPrint("$TAG - Last gps response: ${response.body}");
                var jsonResponse = json.decode(response.body);

                if (jsonResponse.isNotEmpty) {
                    return LastGpsResponse.getLastGpsData(jsonResponse);
                } else {
                    debugPrint('$TAG - Error: Empty or invalid JSON response');
                    return null;
                }
            } else if (response != null) {
                throw Exception('$TAG - Failed to get ship info: ${response.statusCode}');
            } else {
                debugPrint('$TAG - Error: Request failed after retries.');
                return null;
            }
        } on TimeoutException {
            debugPrint('$TAG - Error: Connection timeout while decoding payload data');
            return null;
        } on SocketException {
            debugPrint('$TAG - Error: No Internet connection or server unreachable.');
            return null;
        } on FormatException {
            debugPrint('$TAG - Error: Invalid JSON format in response.');
            return null;
        } catch (e) {
            debugPrint('$TAG - Unexpected error: $e');
            return null;
        }
    }

    // Lay danh sach ban tin MO
    Future<List<PayloadResponse>> getListPayload(String imei, String startDate, String endDate) async {
        final url = Uri.parse('$gstcUrl/api/v2/iri/response/$imei/$startDate/$endDate');

        try {
            var response = await retryRequest(
                maxAttempts: 3,
                delayBetweenRetries: Duration(seconds: 2),
                block: () => httpClient.get(
                    url,
                    headers: {'Authorization': "$authKeyGSTC"},
                ).timeout(timeOutDuration),
            );

            if (response == null) {
                debugPrint('$TAG - Error: Request failed after retries.');
                return [];
            }

            debugPrint("$TAG - Payload response: ${response.body}");

            if (response.statusCode == 200) {
                if (response.body.isEmpty) {
                    debugPrint('$TAG - Error: Response body is empty.');
                    return [];
                }

                try {
                    var jsonResponse = json.decode(response.body);
                    List<PayloadResponse> payloadList = PayloadResponse.fromJson(jsonResponse);

                    // Lọc bỏ null và loại bỏ phần tử trùng lặp
                    List<PayloadResponse> uniquePayloads = payloadList
                        .where((payload) => payload != null) // Loại bỏ null
                        .toSet()
                        .toList(); // Loại bỏ phần tử trùng lặp

                    if (uniquePayloads.isNotEmpty) {
                        return uniquePayloads;
                    } else {
                        debugPrint('$TAG - No data found.');
                        return [];
                    }
                } catch (e) {
                    debugPrint('$TAG - Error: JSON parsing failed - $e');
                    return [];
                }
            } else {
                debugPrint('$TAG - Failed to get payload info: ${response.statusCode}');
                debugPrint('$TAG - Response body: ${response.body}');
                return [];
            }
        } on TimeoutException {
            debugPrint('$TAG - Error: Connection timeout while decoding payload data');
            return [];
        } on SocketException {
            debugPrint('$TAG - Error: No Internet connection or server unreachable.');
            return [];
        } on FormatException {
            debugPrint('$TAG - Error: Invalid JSON format in response.');
            return [];
        } catch (e) {
            debugPrint('$TAG - Unexpected error: $e');
            return [];
        }
    }

    // Lay thong tin tau
    Future<ShipResponse?> getShipInfo(String serialRegister) async {
        final url = Uri.parse('$vhksUrl/api/ship/find').replace(
            queryParameters: {'SerialRegister': serialRegister},
        );

        try {
            // Sử dụng retryRequest để thử lại nếu có lỗi
            var response = await retryRequest(
                maxAttempts: 3, // Số lần thử lại
                delayBetweenRetries: Duration(seconds: 2), // Thời gian chờ giữa các lần thử
                block: () => httpClient.get(
                    url,
                    headers: {'Authorization': "Bearer $authKeyVHKS"},
                ).timeout(timeOutDuration),
            );

            if (response != null && response.statusCode == 200) {
                debugPrint("$TAG - ShipInfo response: ${response.body}");
                var jsonResponse = json.decode(response.body);

                if (jsonResponse is List && jsonResponse.isNotEmpty) {
                    return ShipResponse.getShipData(jsonResponse[0]); // Lấy phần tử đầu tiên của danh sách
                } else {
                    debugPrint('$TAG - Error: Empty or invalid JSON response');
                    return null;
                }
            } else if (response != null) {
                throw Exception('$TAG - Failed to get ship info: ${response.statusCode}');
            } else {
                debugPrint('$TAG - Error: Request failed after retries.');
                return null;
            }
        } on TimeoutException {
            debugPrint('$TAG - Error: Connection timeout while decoding payload data');
            return null;
        } on SocketException {
            debugPrint('$TAG - Error: No Internet connection or server unreachable.');
            return null;
        } on FormatException {
            debugPrint('$TAG - Error: Invalid JSON format in response.');
            return null;
        } catch (e) {
            debugPrint('$TAG - Unexpected error: $e');
            return null;
        }
    }

    // Lay danh sach tau sau khi dang nhap thanh cong
    Future<List<LoginResponse>?> getListShip(String token) async {
        final url = Uri.parse('$loginUrl/api/UserTau/GetAllTauByToken');

        try {
            var response = await retryRequest(
                maxAttempts: 3,
                delayBetweenRetries: Duration(seconds: 2),
                block: () => httpClient.get(
                    url,
                    headers: {'Authorization': "Bearer $token"},
                ).timeout(timeOutDuration),
            );

            if (response == null) {
                debugPrint('$TAG - Error: Request failed after retries.');
                return null;
            }

            debugPrint("$TAG - LoginResponse: ${response.body}");

            if (response.statusCode == 200) {
                if (response.body.trim().isEmpty || response.body == "null") {
                    debugPrint('$TAG - Error: Response body is empty or null.');
                    return null;
                }

                try {
                    var jsonResponse = json.decode(response.body);

                    if (jsonResponse is List && jsonResponse.isNotEmpty) {
                        return jsonResponse.map((item) {
                            try {
                                return LoginResponse.fromJson(item as Map<String, dynamic>);
                            } catch (e) {
                                debugPrint('$TAG - Error parsing item: $item');
                                return null;
                            }
                        }).whereType<LoginResponse>() // Loại bỏ các giá trị null khỏi danh sách
                            .toList();
                    } else {
                        debugPrint('$TAG - Error: Invalid JSON response format');
                        return null;
                    }
                } on FormatException catch (e) {
                    debugPrint('$TAG - Error: JSON parsing failed - $e');
                    return null;
                }
            } else {
                debugPrint('$TAG - Failed to get list ship: ${response.statusCode}');
                debugPrint('$TAG - Response body: ${response.body}');
                return null;
            }
        } on TimeoutException {
            debugPrint('$TAG - Error: Connection timeout');
            return null;
        } on SocketException {
            debugPrint('$TAG - Error: No Internet connection or server unreachable.');
            return null;
        } catch (e) {
            debugPrint('$TAG - Unexpected error: $e');
            return null;
        }
    }

    // Lay thong tin cuoc theo tau
    Future<FeeResponse?> getFeeData(String token, String shipId) async {
        final url = Uri.parse('$loginUrl/api/UserTau/ThongTinCuocTauByToken/$shipId');

        try {
            var response = await retryRequest(
                maxAttempts: 3,
                delayBetweenRetries: Duration(seconds: 2),
                block: () => httpClient.get(
                    url,
                    headers: {'Authorization': "Bearer $token"},
                ).timeout(timeOutDuration),
            );

            if (response == null) {
                debugPrint('$TAG - Error: Request failed after retries.');
                return null;
            }

            debugPrint("$TAG - FeeResponse: ${response.body}");

            if (response.statusCode == 200) {
                if (response.body.trim().isEmpty || response.body == "null") {
                    debugPrint('$TAG - Error: Response body is empty or null.');
                    return null;
                }

                try {
                    var jsonResponse = json.decode(response.body);

                    if (jsonResponse.isNotEmpty) {
                        return FeeResponse.fromJson(jsonResponse);
                    } else {
                        debugPrint('$TAG - Error: Invalid JSON response format');
                        return null;
                    }
                } on FormatException catch (e) {
                    debugPrint('$TAG - Error: JSON parsing failed - $e');
                    return null;
                }
            } else {
                debugPrint('$TAG - Failed to get fee data: ${response.statusCode}');
                debugPrint('$TAG - Response body: ${response.body}');
                return null;
            }
        } on TimeoutException {
            debugPrint('$TAG - Error: Connection timeout');
            return null;
        } on SocketException {
            debugPrint('$TAG - Error: No Internet connection or server unreachable.');
            return null;
        } catch (e) {
            debugPrint('$TAG - Unexpected error: $e');
            return null;
        }
    }

    // Lich su giao dich
    Future<List<FeeHistoryResponse>?> getFeeHistory(String token, String shipId) async {
        final url = Uri.parse('$loginUrl/api/UserTau/GetLichSuThanhToanByToken/$shipId');

        try {
            var response = await retryRequest(
                maxAttempts: 3,
                delayBetweenRetries: Duration(seconds: 2),
                block: () => httpClient.get(
                    url,
                    headers: {'Authorization': "Bearer $token"},
                ).timeout(timeOutDuration),
            );

            if (response == null) {
                debugPrint('$TAG - Error: Request failed after retries.');
                return null;
            }

            debugPrint("$TAG - FeeHistory: ${response.body}");

            if (response.statusCode == 200) {
                if (response.body.trim().isEmpty || response.body == "null") {
                    debugPrint('$TAG - Error: Response body is empty or null.');
                    return null;
                }

                try {
                    var jsonResponse = json.decode(response.body);

                    if (jsonResponse is List && jsonResponse.isNotEmpty) {
                        return jsonResponse.map((item) {
                            try {
                                return FeeHistoryResponse.fromJson(item as Map<String, dynamic>);
                            } catch (e) {
                                debugPrint('$TAG - Error parsing item: $item');
                                return null;
                            }
                        })
                            .whereType<FeeHistoryResponse>() // Loại bỏ các giá trị null khỏi danh sách
                            .toList();
                    } else {
                        debugPrint('$TAG - Error: Invalid JSON response format');
                        return null;
                    }
                } on FormatException catch (e) {
                    debugPrint('$TAG - Error: JSON parsing failed - $e');
                    return null;
                }
            } else {
                debugPrint('$TAG - Failed to get fee history data: ${response.statusCode}');
                debugPrint('$TAG - Response body: ${response.body}');
                return null;
            }
        } on TimeoutException {
            debugPrint('$TAG - Error: Connection timeout');
            return null;
        } on SocketException {
            debugPrint('$TAG - Error: No Internet connection or server unreachable.');
            return null;
        } catch (e) {
            debugPrint('$TAG - Unexpected error: $e');
            return null;
        }
    }

    /// ================ POST =================================================

    // Dang nhap tai khoan
    Future<TokenResponse?> loginUser(String username, String password) async {
        final url = Uri.parse('$loginUrl/api/Account/loginuser');

        Map<String, String> headers = {
            "Content-Type": "application/json"
        };

        Map<String, dynamic> request = {
            "username": username,
            "password":  password,
        };

        var jsonBody = utf8.encode(json.encode(request));

        try {
            var response = await http.post(
                url,
                body: jsonBody,
                headers: headers,
            ).timeout(timeOutDuration);

            debugPrint("$TAG - Data encoded: ${response.body}");

            if (response.statusCode == 200 || response.statusCode == 201) {
                if (response.body.trim().isEmpty || response.body == "null") {
                    debugPrint('$TAG - Error: Response body is empty or null.');
                    return null;
                }

                try {
                    var jsonResponse = json.decode(response.body);

                    if (jsonResponse.isNotEmpty) {
                        return TokenResponse.fromJson(jsonResponse);
                    } else {
                        debugPrint('$TAG - Error: Invalid JSON response format');
                        return null;
                    }
                } on FormatException catch (e) {
                    debugPrint('$TAG - Error: JSON parsing failed - $e');
                    return null;
                }
            } else {
                debugPrint('$TAG - Response body: ${response.body}');
                return null;
            }
        } on TimeoutException {
            debugPrint('$TAG - Error: Connection timeout');
            return null;
        } on SocketException {
            debugPrint('$TAG - Error: No Internet connection or server unreachable.');
            return null;
        } on FormatException {
            debugPrint('$TAG - Error: Invalid JSON format in response.');
            return null;
        } catch (e) {
            debugPrint('$TAG - Unexpected error: $e');
            return null;
        }
    }

    // Refresh token
    Future<TokenResponse?> refreshToken(String accessToken, String refreshToken) async {
        final url = Uri.parse('$loginUrl/api/Account/ResetToken');

        Map<String, String> headers = {
            "Content-Type": "application/json",
            'Authorization': "Bearer $accessToken"
        };

        var jsonBody = utf8.encode(json.encode(refreshToken));

        try {
            var response = await http.post(
                url,
                body: jsonBody,
                headers: headers,
            ).timeout(timeOutDuration);

            if (response.statusCode == 200 || response.statusCode == 201) {
                if (response.body.trim().isEmpty || response.body == "null") {
                    debugPrint('$TAG - Error: Response body is empty or null.');
                    return null;
                }

                try {
                    var jsonResponse = json.decode(response.body);

                    if (jsonResponse.isNotEmpty) {
                        return TokenResponse.fromJson(jsonResponse);
                    } else {
                        debugPrint('$TAG - Error: Invalid JSON response format');
                        return null;
                    }
                } on FormatException catch (e) {
                    debugPrint('$TAG - Error: JSON parsing failed - $e');
                    return null;
                }
            } else {
                debugPrint('$TAG - Response body: ${response.body}');
                return null;
            }
        } on TimeoutException {
            debugPrint('$TAG - Error: Connection timeout');
            return null;
        } on SocketException {
            debugPrint('$TAG - Error: No Internet connection or server unreachable.');
            return null;
        } on FormatException {
            debugPrint('$TAG - Error: Invalid JSON format in response.');
            return null;
        } catch (e) {
            debugPrint('$TAG - Unexpected error: $e');
            return null;
        }
    }

    // Giai ma payload
    Future<dynamic> enCodePayload(String payload, int length) async {
        final url = Uri.parse('$vhksUrl/api/v1/parse-data/hex-format');

        Map<String, String> headers = {
            'Authorization': "Bearer $authKeyVHKS",
            "Content-Type": "application/json"
        };

        Map<String, dynamic> request = {
            "payload": payload,
        };

        var jsonBody = utf8.encode(json.encode(request));

        try {
            var response = await retryRequest(
                maxAttempts: 3,
                delayBetweenRetries: Duration(seconds: 2),
                block: () => http.post(
                    url,
                    body: jsonBody,
                    headers: headers,
                ).timeout(timeOutDuration),
            );

            if (response == null) {
                debugPrint('$TAG - Error: Request failed after retries.');
                return null;
            }

            debugPrint("$TAG - Data encoded: ${response.body}");

            if (response.statusCode == 200 || response.statusCode == 201) {
                var jsonResponse = json.decode(response.body);
                if (jsonResponse.isNotEmpty) {
                    if(length == 15) {
                        return GpsResponse15Bytes.fromJson(jsonResponse);
                    }else if(length == 10){
                        return GpsResponse10Bytes.fromJson(jsonResponse);
                    }else if(length == 23){
                        return GpsResponse23Bytes.fromJson(jsonResponse);
                    }
                } else {
                    debugPrint('$TAG - Error: Invalid JSON response format');
                    return null;
                }
            } else {
                debugPrint('$TAG - Error: Failed to get gps log data - Status Code: ${response.statusCode}');
                debugPrint('$TAG - Response body: ${response.body}');
                return null;
            }
        } on TimeoutException {
            debugPrint('$TAG - Error: Connection timeout while decoding payload data');
            return null;
        } on SocketException {
            debugPrint('$TAG - Error: No Internet connection or server unreachable.');
            return null;
        } on FormatException {
            debugPrint('$TAG - Error: Invalid JSON format in response.');
            return null;
        } catch (e) {
            debugPrint('$TAG - Unexpected error: $e');
            return null;
        }
    }

    // Dong bo du lieu
    Future<bool> syncData() async {
        final url = Uri.parse('$vhksUrl/api/ship/sync');

        Map<String, String> headers = {
            'Authorization': "Bearer $authKeyVHKS",
            "Content-Type": "application/json"
        };

        try{
            var response = await http.post(
                url,
                headers: headers,
            ).timeout(timeOutDuration);

            debugPrint("$TAG - Response: ${response.body}");

            if (response.statusCode == 200 || response.statusCode == 201) {
                var jsonResponse = json.decode(response.body);
                if (jsonResponse.isNotEmpty) {
                    return true;
                } else {
                    debugPrint('$TAG - Error: Invalid JSON response format');
                    return false;
                }
            } else {
                debugPrint('$TAG - Error: Failed to get gps log data - Status Code: ${response.statusCode}');
                debugPrint('$TAG - Response body: ${response.body}');
                return false;
            }
        } on TimeoutException {
            debugPrint('$TAG - Error: Connection timeout while decoding payload data');
            return false;
        } on SocketException {
            debugPrint('$TAG - Error: No Internet connection or server unreachable.');
            return false;
        } on FormatException {
            debugPrint('$TAG - Error: Invalid JSON format in response.');
            return false;
        } catch (e) {
            debugPrint('$TAG - Unexpected error: $e');
            return false;
        }
    }

    /// ================ UTILITY =================================================
    // Gui lai yeu cau
    Future<http.Response?> retryRequest<T>({
        int maxAttempts = 3,
        Duration delayBetweenRetries = const Duration(seconds: 2),
        required Future<http.Response> Function() block,
    }) async {
        int currentAttempt = 0;
        http.Response? response;

        while (currentAttempt < maxAttempts) {
            try {
                response = await block();

                // Nếu HTTP status là 2xx thì thoát vòng lặp, không retry
                if (response.statusCode >= 200 && response.statusCode < 300) {
                    return response;
                }

                // Nếu lỗi là 4xx (client error) thì không retry
                if (response.statusCode >= 400 && response.statusCode < 500) {
                    debugPrint('$TAG - Error ${response.statusCode}: Client error, no retry needed.');
                    return response;
                }

            } on SocketException catch (e) {
                debugPrint('$TAG - Attempt ${currentAttempt + 1}: No internet connection - $e');
            } on TimeoutException catch (e) {
                debugPrint('$TAG - Attempt ${currentAttempt + 1}: Timeout error - $e');
            } on Exception catch (e) {
                debugPrint('$TAG - Attempt ${currentAttempt + 1}: Unexpected error - $e');
            }

            currentAttempt++;
            if (currentAttempt < maxAttempts) {
                debugPrint('$TAG - Retrying request... Attempt $currentAttempt');
                await Future.delayed(delayBetweenRetries);
            }
        }

        return response;
    }

    // Giai phong tai nguyen
    void dispose() {
        httpClient.close();
    }
}