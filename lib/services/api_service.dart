import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // 1. [NCP 키] 지도, Geocoding, STT용 (네이버 클라우드 플랫폼)
  static const String _ncpClientId = 'ncpClientID';
  static const String _ncpClientSecret = 'ncpClientSecreet';

  // 2. [OpenAPI 키]  (네이버 디벨로퍼스)
  static const String _openApiClientId = 'Naver_developerClientID';
  static const String _openApiClientSecret = 'Naver_developerClientSecret';

  // [서버 설정] Spring Boot 주소
  static const String _baseUrl = 'http://34.47.118.174:8080/api/chat';

  // --- 1. STT (Speech to Text) ---
  Future<String> textToSpeech(String filePath) async {
    const String lang = "Kor";
    final url = Uri.parse('https://naveropenapi.apigw.ntruss.com/recog/v1/stt?lang=$lang');

    try {
      File audioFile = File(filePath);
      List<int> audioBytes = await audioFile.readAsBytes();

      final response = await http.post(
        url,
        headers: {
          "X-NCP-APIGW-API-KEY-ID": _ncpClientId,
          "X-NCP-APIGW-API-KEY": _ncpClientSecret,
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

  // --- 2. Spring Boot 통신 (Start) ---
  Future<Map<String, dynamic>> startChat(String category, String text) async {
    final url = Uri.parse('$_baseUrl/start');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({ "category": category, "sttText": text }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) { print("Start Chat Error: $e"); }
    return {};
  }

  // --- 3. Spring Boot 통신 (Select) ---
  Future<Map<String, dynamic>> selectChunk(int sessionId, String selectedText) async {
    final url = Uri.parse('$_baseUrl/select');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({ "sessionId": sessionId, "selectedText": selectedText }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) { print("Select Chunk Error: $e"); }
    return {};
  }

  // --- 4. [New] 좌표 -> 주소 변환 (Reverse Geocoding) ---
  // 현재 지도 중심이 무슨 동인지 알아내기 위함
  // --- 4. 좌표 -> 주소 변환 (Reverse Geocoding) ---
  Future<String> reverseGeocode(double lat, double lng) async {
    // 좌표가 (0,0)인지 확인
    if (lat == 0 || lng == 0) {
      print("❌ 좌표 오류: (0, 0)입니다. 에뮬레이터 위치를 확인하세요.");
      return "서울";
    }

    final url = Uri.parse('https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?coords=$lng,$lat&output=json&orders=addr,roadaddr');

    try {
      final response = await http.get(url, headers: {
        "X-NCP-APIGW-API-KEY-ID": _ncpClientId,
        "X-NCP-APIGW-API-KEY": _ncpClientSecret,
      });

      // [디버깅용 로그] 상태 코드와 응답 내용 출력
      print("📍 Reverse Geocode 상태 코드: ${response.statusCode}");
      // print("📍 응답 본문: ${utf8.decode(response.bodyBytes)}"); // 필요하면 주석 해제

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json['status']['code'] == 0) { // 성공 코드 0 확인
          final results = json['results'];
          if (results != null && results.length > 0) {
            final region = results[0]['region'];
            String area1 = region['area1']['name'] ?? "";
            String area2 = region['area2']['name'] ?? "";
            String area3 = region['area3']['name'] ?? "";
            String result = "$area1 $area2 $area3".trim();
            print("✅ 변환 성공: $result");
            return result;
          }
        } else {
          print("❌ API 응답 실패: ${json['status']['message']}");
        }
      } else {
        print("❌ HTTP 에러: ${response.statusCode}");
        print("❌ 내용: ${utf8.decode(response.bodyBytes)}");
      }
    } catch (e) {
      print("❌ Reverse Geocode 예외 발생: $e");
    }
    return "서울"; // 실패 시 기본값
  }

  // --- 5. [New] 검색 API (Local Search) ---
  // "역삼동 카페" 등으로 검색하여 결과 리스트 반환
  Future<List<dynamic>> searchLocal(String query) async {
    final url = Uri.parse('https://openapi.naver.com/v1/search/local.json?query=$query&display=5&sort=random');
    try {
      final response = await http.get(url, headers: {
        "X-Naver-Client-Id": _openApiClientId,
        "X-Naver-Client-Secret": _openApiClientSecret,
      });
      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return json['items']; // 검색 결과 리스트 반환
      }
    } catch (e) { print("Search API Error: $e"); }
    return [];
  }

  // --- 6. [New] 주소 -> 좌표 변환 (Geocoding) ---
  // 검색 결과(주소)를 지도에 찍을 좌표로 변환
  Future<Map<String, double>?> geocode(String address) async {
    final url = Uri.parse('https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=$address');
    try {
      final response = await http.get(url, headers: {
        "X-NCP-APIGW-API-KEY-ID": _ncpClientId,
        "X-NCP-APIGW-API-KEY": _ncpClientSecret,
      });
      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json['addresses'] != null && json['addresses'].length > 0) {
          final item = json['addresses'][0];
          return {
            "lat": double.parse(item['y']),
            "lng": double.parse(item['x']),
          };
        }
      }
    } catch (e) { print("Geocode Error: $e"); }
    return null;
  }
}