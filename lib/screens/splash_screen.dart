
import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhks/api/response/token_response.dart';
import 'package:vhks/screens/login_screen.dart';

import '../api/request/api_service.dart';
import '../api/response/LoginResponse.dart';
import '../ui/colors.dart';
import '../utility/constants.dart';
import '../utility/function_support.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget  {
    const SplashScreen({super.key});

    @override
    State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

    final String TAG = "SplashScreen";

    late ApiService _apiService;
    late FunctionSupport _support;
    bool _isLoading = false;

    @override
    void initState() {
        super.initState();

        _apiService = ApiService();
        _support = FunctionSupport();

        syncData();
    }

    @override
    void dispose() {
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: AppColors.white,
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
                            "Đang đồng bộ dữ liệu...",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black38,
                            ),
                        ),
                    ],
                ),
            )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[

                    Image.asset(
                        'assets/header_blue.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                    ),

                    const Spacer(),

                    Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[

                            Image.asset(
                                'assets/family.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                            ),

                            const SizedBox(height: 5),

                            const Text(
                                'Giám sát tàu cá',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                ),
                            ),

                            const SizedBox(height: 10),

                            CupertinoButton(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(15.0),
                                onPressed: (){
                                    syncData();
                                },
                                child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        Text(
                                            "Thử lại",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500,
                                            ),
                                        ),
                                        SizedBox(width: 8.0),
                                        Icon(
                                            Icons.refresh,
                                            size: 20.0,
                                            color: Colors.white,
                                        ),
                                    ],
                                ),
                            )
                        ],
                    ),

                    const Spacer(),

                    Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                            Image.asset(
                                'assets/logo.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                                'Phiên bản v1.0',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                ),
                            ),
                            const SizedBox(height: 10),
                        ],
                    )
                ]
            )
        );
    }

    // Dong bo du lieu
    Future<void> syncData() async {
        setState(() => _isLoading = true);
        try {
            bool isSyncSuccess = await _apiService.syncData();

            if (isSyncSuccess) {
                _support.showSnackbar(context, 'Đã đồng bộ dữ liệu', Colors.greenAccent);
                await _loadLoginInfo();
            } else {
                setState(() => _isLoading = false);
                debugPrint("$TAG - Không thể đồng bộ dữ liệu");
                _support.showSnackbar(context, 'Không thể đồng bộ dữ liệu!\nKiểm tra lại kết nối mạng', Colors.redAccent);
            }
        } catch (exception) {
            print("$TAG - Error: $exception");
            setState(() => _isLoading = false);
            _support.showSnackbar(context, 'Đã có lỗi xảy ra trong quá trình xử lý!\nKiểm tra lại kết nối mạng', Colors.redAccent);
        }
    }

    // Lay gia tri thong tin tau da luu
    Future<void> _loadLoginInfo() async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String accessToken = prefs.getString(Constants.LOGIN_TOKEN) ?? "";
        String refreshToken = prefs.getString(Constants.LOGIN_REFRESH_TOKEN) ?? "";

        debugPrint("$TAG - current access token: " + accessToken);
        debugPrint("$TAG - current refresh token: " + refreshToken);

        if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
            TokenResponse? tokenResponse = await handleRefreshToken(accessToken, refreshToken);
            if (tokenResponse != null) {
                debugPrint("$TAG - new access token: " + tokenResponse.token);
                debugPrint("$TAG - new refresh token: " + tokenResponse.refreshToken);
                // Lấy danh sách tàu và chuyển sang màn hình chính
                await getListShip(tokenResponse);
                _saveLoginInfo(tokenResponse);
            } else {
                _support.navigateAndFinish(context, LoginScreen());
            }
        } else {
            _support.navigateAndFinish(context, LoginScreen());
            debugPrint("$TAG - Chưa có thông tin đăng nhập!");
        }
    }

    // Lay danh sach tau
    Future<void> getListShip(TokenResponse tokenResponse) async
    {
        try{
            List<LoginResponse>? ships = await _apiService.getListShip(tokenResponse.token);
            if(ships!= null && ships.isNotEmpty) {
                _support.navigateAndFinish(context, HomeScreen(ships: ships, tokenResponse: tokenResponse));
            } else{
                _support.navigateAndFinish(context, LoginScreen());
                debugPrint("$TAG - Không có tàu cá nào tương ứng với tài khoản này!");
            }
        } catch (e) {
            _support.navigateAndFinish(context, LoginScreen());
            print(e);
        }
    }

    // Refresh token
    Future<TokenResponse?> handleRefreshToken(String accessToken, String oldRefreshToken) async {
        try {
            return await _apiService.refreshToken(accessToken, oldRefreshToken);
        } catch (e) {
            debugPrint("$TAG - Error: $e");
            return null;
        }
    }

    // Luu thong tin dang nhap lan dau
    Future<void> _saveLoginInfo(TokenResponse token) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(Constants.LOGIN_TOKEN, token.token);
        await prefs.setString(Constants.LOGIN_REFRESH_TOKEN, token.refreshToken);
        await prefs.commit();
        debugPrint("$TAG - Đã lưu thông tin đăng nhập");
    }
}