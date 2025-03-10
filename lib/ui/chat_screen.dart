import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
    const ChatScreen({super.key});

    @override
    State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
      @override
      Widget build(BuildContext context) {
          return Scaffold(
              body: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Image.asset(
                              'assets/chat.png',
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                          ),
                          const SizedBox(height: 20,),
                          Text(
                              'Chưa có cuộc trò chuyện nào!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10,),
                          Text(
                              'Đăng ký dịch vụ nhắn tin để sử dụng.',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                              textAlign: TextAlign.center,
                          ),
                      ],
                  ),
              ),
          );
      }
}