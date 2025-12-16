import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: 'YOUR_KAKAO_APP_KEY');

  // 2. 네이버 지도 초기화 (최종 수정)
  // [설명] 최신 버전에서는 FlutterNaverMap() 객체를 생성한 뒤 .init()을 호출해야 합니다.
  await FlutterNaverMap().init(
    clientId: 'ho5etl22ab',
    onAuthFailed: (ex) => print("네이버 지도 인증 실패: $ex"),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AAC Service',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}


