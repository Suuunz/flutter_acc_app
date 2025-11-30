import 'package:flutter/material.dart';


class AppColors {
  // AACommu 스타일의 메인 컬러 (부드러운 보라/파랑 계열)
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFFE3E3F5);
  static const Color background = Color(0xFFF7F8FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textGray = Color(0xFF888888);
  static const Color white = Colors.white;
}

class AppTextStyles {
  // [수정] notoSansKr() 대신 getFont('Noto Sans KR') 사용
  static const TextStyle header = TextStyle(
      fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark
  );

  static const TextStyle body = TextStyle(
      fontSize: 16, color: AppColors.textDark
  );

  static const TextStyle chunkTitle = TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark
  );
}