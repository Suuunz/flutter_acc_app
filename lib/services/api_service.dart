import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // [키 설정] 네이버 클라우드 키
  static const String _clientId = 'your clientid';
  static const String _clientSecret = 'your clientsecret';

  // [서버 설정] GCP 외부 IP
  static const String _baseUrl = 'http://34.47.118.174:8080/api/chat';

  // 1. Naver STT
  Future<String> textToSpeech(String filePath) async {
    const String lang = "Kor";
    final url = Uri.parse('https://naveropenapi.apigw.ntruss.com/recog/v1/stt?lang=$lang');

    try {
      File audioFile = File(filePath);
      List<int> audioBytes = await audioFile.readAsBytes();

      final response = await http.post(
        url,
        headers: {
          "X-NCP-APIGW-API-KEY-ID": _clientId,
          "X-NCP-APIGW-API-KEY": _clientSecret,
          "Content-Type": "application/octet-stream",
        },
        body: audioBytes,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse['text'];
      }
      return "";
    } catch (e) {
      print("STT Error: $e");
      return "";
    }
  }

  // 2. 대화 시작 (Start) - sessionId와 리스트를 Map으로 반환
  Future<Map<String, dynamic>> startChat(String category, String text) async {
    final url = Uri.parse('$_baseUrl/start');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "category": category,
          "sttText": text
        }),
      );

      if (response.statusCode == 200) {
        // Spring에서 온 { "sessionId": 1, "topKChunks": [...] } 파싱
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Start Chat Error: $e");
    }
    return {}; // 실패 시 빈 맵 반환
  }

  // 3. 청크 선택 (Select) - 선택한 텍스트 보내고 다음 추천 받기
  Future<Map<String, dynamic>> selectChunk(int sessionId, String selectedText) async {
    final url = Uri.parse('$_baseUrl/select');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sessionId": sessionId,
          "selectedText": selectedText
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Select Chunk Error: $e");
    }
    return {};
  }
}