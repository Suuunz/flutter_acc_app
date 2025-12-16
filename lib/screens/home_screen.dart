import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../constants/theme.dart';
import '../services/api_service.dart';
import '../widgets/record_button.dart';
import '../widgets/result_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  // TTS 객체
  final FlutterTts _tts = FlutterTts();

  bool _isLoading = false;
  bool _isRecording = false;

  String _selectedStore = "현재 위치";
  // [수정] 기본값 카페
  String _selectedCategory = "cafe";

  int? _currentSessionId;
  String _currentSttText = "";
  List<String> _currentRecommendations = [];
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("ko-KR");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _tts.speak(text);
    }
  }

  Future<void> _initRecorder() async {
    await [Permission.microphone, Permission.location].request();
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _tts.stop();
    super.dispose();
  }

  // --- 녹음 및 서버 통신 ---
  Future<void> _handleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      setState(() { _isRecording = false; _isLoading = true; });

      if (path != null) {
        try {
          // 1. STT 변환
          String sttText = await _apiService.textToSpeech(path);

          // 2. 서버 요청 로직 수정
          // [핵심 수정] 'others'가 선택되었을 경우 빈 문자열("") 전송, 아니면 해당 키값 전송
          String categoryToSend = _selectedCategory == 'others' ? "" : _selectedCategory;

          print("전송 카테고리: '$categoryToSend', STT: $sttText"); // 디버깅용 로그

          final result = await _apiService.startChat(categoryToSend, sttText);

          setState(() {
            _isLoading = false;
            _currentSessionId = result['sessionId'];
            _currentRecommendations = List<String>.from(result['topKChunks']);
            _currentSttText = sttText;
            _history = [];
          });

          _showResultSheet();

        } catch (e) {
          print("에러: $e");
          setState(() => _isLoading = false);
        }
      }
    } else {
      final dir = await getTemporaryDirectory();
      await _recorder.startRecorder(
        toFile: '${dir.path}/aac_temp.aac',
        codec: Codec.aacADTS,
      );
      setState(() => _isRecording = true);
    }
  }

  Future<void> _handleChunkSelect(String selectedText) async {
    if (_currentSessionId == null) return;

    Navigator.pop(context);
    setState(() {
      _isLoading = true;
      _history.add(selectedText);
    });

    try {
      final result = await _apiService.selectChunk(_currentSessionId!, selectedText);

      setState(() {
        _isLoading = false;
        _currentRecommendations = List<String>.from(result['topKChunks']);
      });

      _showResultSheet();

    } catch (e) {
      print("선택 에러: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- 문장 완성 ---
  void _handleComplete() {
    Navigator.pop(context);
    String finalSentence = _history.join(" ");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary),
            SizedBox(width: 8),
            Text("완성된 문장"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _speak(finalSentence),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  finalSentence.isEmpty ? "선택된 문장이 없습니다." : finalSentence,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _speak(finalSentence),
                icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                label: const Text("소리로 듣기", style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _tts.stop();
              Navigator.pop(context);
            },
            child: const Text("닫기", style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }

  void _showResultSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResultSheet(
        storeName: _selectedStore,
        sttText: _currentSttText,
        history: _history,
        recommendations: _currentRecommendations,
        onChunkSelected: _handleChunkSelect,
        onComplete: _handleComplete,
      ),
    );
  }

  List<NMarker> _createDemoMarkers() {
    final marker1 = NMarker(
      id: '1',
      position: const NLatLng(37.5665, 126.9780),
      caption: const NOverlayCaption(text: "스타벅스"),
    );
    marker1.setOnTapListener((overlay) {
      setState(() {
        _selectedStore = "스타벅스 시청점";
        _selectedCategory = "cafe";
      });
    });
    return [marker1];
  }

  // --- [NEW] 컨텍스트 선택 버튼 위젯 ---
  Widget _buildContextSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCategoryBtn("cafe", "☕ 카페"),
          const SizedBox(width: 5),
          _buildCategoryBtn("restaurant", "🍽️ 식당"),
          const SizedBox(width: 5),
          // [수정] 병원 -> 기타(others)로 변경
          _buildCategoryBtn("others", "💬 기타"),
        ],
      ),
    );
  }

  Widget _buildCategoryBtn(String key, String label) {
    bool isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = key;
          // [수정] 기타 선택 시 상단 표시 텍스트 변경
          if (key == 'others') {
            _selectedStore = "일반 대화 모드";
          } else {
            _selectedStore = "현재 위치: $label";
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("AACommu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: NaverMap(
              options: const NaverMapViewOptions(
                locationButtonEnable: true,
              ),
              onMapReady: (controller) {
                _mapControllerCompleter.complete(controller);
                controller.addOverlayAll(_createDemoMarkers().toSet());
              },
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildContextSelector(),
                RecordButton(
                  isRecording: _isRecording,
                  isLoading: _isLoading,
                  onTap: _handleRecording,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}