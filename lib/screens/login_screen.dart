import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhks/api/response/LoginResponse.dart';
import 'package:vhks/api/response/token_response.dart';
import 'package:vhks/screens/home_screen.dart';
import 'package:vhks/ui/colors.dart';
import 'package:vhks/utility/function_support.dart';

import '../api/request/api_service.dart';
import '../utility/constants.dart';

class LoginScreen extends StatefulWidget{
    const LoginScreen({super.key});

    @override
    State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{

    final String TAG = "LoginScreen";

    late ApiService _apiService;
    late FunctionSupport _support;
    late String username = "";
    late String password = "";
    final TextEditingController _controllerUsername = TextEditingController();
    final TextEditingController _controllerPassword = TextEditingController();

        @override
      void initState() {
        // TODO: implement initState
        super.initState();
        _apiService = ApiService();
        _support = FunctionSupport();
      }

      @override
      void dispose() {
        // TODO: implement dispose
        super.dispose();
      }

      @override
      Widget build(BuildContext context) {
            return Scaffold(
                resizeToAvoidBottomInset: false,
                body: GestureDetector(
                    behavior: HitTestBehavior.opaque, // Giúp GestureDetector nhận sự kiện chạm trên toàn bộ màn hình
                    onTap: () {
                        FocusScope.of(context).requestFocus(FocusNode()); // Ẩn bàn phím ảo
                    },
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                          Image.asset(
                              'assets/header_blue.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                          ),
                  
                          Expanded(
                            child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                color: AppColors.white,
                                child: Column(
                                    children: <Widget>[
                                        const Text(
                                            "Đăng nhập",
                                            style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueAccent
                                            ),
                                        ),
                  
                                        const SizedBox(height: 20),
                  
                                        TextFormField(
                                            keyboardType: TextInputType.phone,
                                            controller: _controllerUsername,
                                            decoration: InputDecoration(
                                                hintText: "Nhập tên tài khoản...",
                                                border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(20.0), // Bo góc
                                                    borderSide: BorderSide(color: Colors.grey), // Màu viền
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(20.0),
                                                    borderSide: BorderSide(color: Colors.grey, width: 1.0), // Viền khi không chọn
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(20.0),
                                                    borderSide: BorderSide(color: Colors.blueAccent, width: 2.0), // Viền khi chọn
                                                ),
                                                contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                  
                                                suffixIcon: _controllerUsername.text.isNotEmpty
                                                    ? IconButton(
                                                    icon: const Icon(Icons.clear, color: Colors.red),
                                                    onPressed: (){
                                                        _controllerUsername.clear();
                                                        setState((){
                  
                                                        });
                                                    }) : null,
                                            ),
                                            onChanged: (value){
                                                setState((){
                                                    username = value;
                                                });
                                            },
                                        ),
                  
                                        const SizedBox(height: 16),
                  
                                        TextFormField(
                                            keyboardType: TextInputType.visiblePassword,
                                            obscureText: true,
                                            controller: _controllerPassword,
                                            decoration: InputDecoration(
                                                hintText: "Nhập mật khẩu...",
                                                border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(20.0), // Bo góc
                                                    borderSide: BorderSide(color: Colors.grey), // Màu viền
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(20.0),
                                                    borderSide: BorderSide(color: Colors.grey, width: 1.0), // Viền khi không chọn
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(20.0),
                                                    borderSide: BorderSide(color: Colors.blueAccent, width: 2.0), // Viền khi chọn
                                                ),
                                                contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                  
                                                suffixIcon: _controllerPassword.text.isNotEmpty
                                                    ? IconButton(
                                                    icon: const Icon(Icons.clear, color: Colors.red),
                                                    onPressed: (){
                                                        _controllerPassword.clear();
                                                        setState((){
                  
                                                        });
                                                    }) : null,
                                            ),
                                            onChanged: (value){
                                                setState((){
                                                    password = value;
                                                });
                                            },
                                        ),
                  
                                        const SizedBox(height: 16),
                  
                                        InkWell(
                                            onTap: () {
                                                loginAccount(username, password,
                                                    onSuccess: (token) {
                                                        getListShip(token);
                                                        _saveLoginInfo(token);
                                                        debugPrint("$TAG - Đăng nhập thành công!");
                                                        _support.showSnackbar(context, "Đăng nhập thành công!", Colors.greenAccent);
                                                    },
                                                    onFailure: () {
                                                        debugPrint("$TAG - Đăng nhập thất bại!");
                                                        _support.showSnackbar(context, "Đăng nhập thất bại\n Hãy kiểm tra lại thông tin đăng nhập và kết nối mạng", Colors.orangeAccent);
                                                    }
                                                );
                                            },
                                            child: Material(
                                                elevation: 5,
                                                borderRadius: BorderRadius.circular(15),
                                                color: Colors.blueAccent,
                                                  child: Container(
                                                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                                      child: const Text(
                                                          "Đăng nhập",
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.white,
                                                          ),
                                                      ),
                                                  ),
                                            ),
                                        )
                                    ]
                                ),
                            ),
                          ),
                  
                          Container(
                              width: double.infinity,
                              color: AppColors.white,
                            child: Column(
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
                            ),
                          )
                      ],
                  ),
                ),
            );
      }

      // Lay danh sach tau
      Future<void> getListShip(TokenResponse tokenResponse) async
      {
            try{
                List<LoginResponse>? ships = await _apiService.getListShip(tokenResponse.token);
                if(ships!= null && ships.isNotEmpty) {
                    _support.navigateAndFinish(context, HomeScreen(ships: ships, tokenResponse: tokenResponse));
                } else{
                    debugPrint("$TAG - Không có tàu cá nào tương ứng với tài khoản này!")                                                                                                               ;
                    _support.showSnackbar(context, "Không có tàu cá nào tương ứng với tài khoản này!\nVui lòng thử lại!", Colors.redAccent);
                }
            } catch (e) {
                _support.showSnackbar(context, "Lỗi kết nối!\nHãy kiểm tra lại đường truyền", Colors.redAccent);
                print(e);
            }
      }

      // Dang nhap tai khoan
      Future<void> loginAccount(String username, String password, {required Function onSuccess, required Function onFailure}) async
      {
            try{
                TokenResponse? tokenResponse = await _apiService.loginUser(username, password);
                if(tokenResponse!= null) {
                    debugPrint("$TAG - first access token: " + tokenResponse.token);
                    debugPrint("$TAG - first refresh token: " + tokenResponse.refreshToken);
                    onSuccess(tokenResponse);
                }else{
                    onFailure();
                }
            } catch (e) {
                _support.showSnackbar(context, "Đăng nhập thất bại!\nHãy kiểm tra lại đường truyền", Colors.orangeAccent);
                print(e);
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