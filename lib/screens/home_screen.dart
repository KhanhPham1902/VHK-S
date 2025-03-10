import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vhks/api/response/token_response.dart';
import 'package:vhks/screens/login_screen.dart';
import 'package:vhks/ui/chat_screen.dart';
import 'package:vhks/ui/colors.dart';
import 'package:vhks/ui/map_screen.dart';
import 'package:vhks/ui/profile_screen.dart';
import 'package:vhks/utility/function_support.dart';

import '../api/response/LoginResponse.dart';
import '../utility/constants.dart';

class HomeScreen extends StatefulWidget{
    final List<LoginResponse> ships;
    final TokenResponse tokenResponse;
    const HomeScreen({Key? key, required this.ships, required this.tokenResponse}) : super(key: key);

    @override
    State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

    int _selectedIndex = 0;

        @override
      void initState() {
            super.initState();
      }

      @override
      void dispose() {
        super.dispose();
      }

      @override
      Widget build(BuildContext context) {
          final List<Widget> _screenOptions = [
              MapScreen(ships: widget.ships),
              ChatScreen(),
              ProfileScreen(ships: widget.ships, tokenResponse: widget.tokenResponse)
          ];

            return SafeArea(
              child: Scaffold(
                  bottomNavigationBar: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                              BoxShadow(
                                  blurRadius: 20,
                                  color: Colors.black.withOpacity(.1),
                              )
                          ]
                      ),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                        child: GNav(
                            rippleColor: Colors.grey[300]!,
                            hoverColor: Colors.grey[100]!,
                            activeColor: Colors.black,
                            iconSize: 24,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            duration: Duration(milliseconds: 400),
                            tabBackgroundColor: Colors.grey[100]!,
                            color: Colors.blueAccent,
                            tabs: [
                              GButton(
                                  icon: Icons.near_me_sharp,
                                  text: 'Giám sát ',
                                  backgroundColor: Colors.blueAccent,
                                  iconActiveColor: Colors.white,
                                  textColor: Colors.white,
                              ),
                              GButton(
                                  icon: Icons.chat,
                                  text: 'Nhắn tin',
                                  backgroundColor: Colors.redAccent,
                                  iconActiveColor: Colors.white,
                                  textColor: Colors.white,
                              ),
                              GButton(
                                  icon: Icons.person_sharp,
                                  text: 'Thông tin',
                                  backgroundColor: Colors.greenAccent,
                                  iconActiveColor: Colors.white,
                                  textColor: Colors.white,
                              )
                          ],
              
                            selectedIndex: _selectedIndex,
                            onTabChange: (index) {
                                setState(() {
                                    _selectedIndex = index;
                                });
                            },
                      ),
                    ),
                  ),
              
                  body: _screenOptions.elementAt(_selectedIndex)
              ),
            );
      }
}