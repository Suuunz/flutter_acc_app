import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

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

  bool _isLoading = false;
  bool _isRecording = false;

  // 상태 변수들
  String _selectedStore = "매장을 선택해주세요";
  String _selectedCategory = "cafe";
  int? _currentSessionId;
  String _currentSttText = ""; // [New] STT 원문 저장
  List<String> _currentRecommendations = [];
  List<String> _history = [];  // [New] 선택된 청크들 저장

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await [Permission.microphone, Permission.location].request();
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  // --- 1. 녹음 종료 및 첫 요청 ---
  Future<void> _handleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      setState(() { _isRecording = false; _isLoading = true; });

      if (path != null) {
        try {
          String sttText = await _apiService.textToSpeech(path);

          final result = await _apiService.startChat(_selectedCategory, sttText);

          setState(() {
            _isLoading = false;
            _currentSessionId = result['sessionId'];
            _currentRecommendations = List<String>.from(result['topKChunks']);
            _currentSttText = sttText; // STT 저장
            _history = []; // 히스토리 초기화
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

  // --- 2. 청크 선택 로직 ---
  Future<void> _handleChunkSelect(String selectedText) async {
    if (_currentSessionId == null) return;

    Navigator.pop(context); // 로딩을 위해 닫기
    setState(() {
      _isLoading = true;
      _history.add(selectedText); // [New] 선택한 문장을 히스토리에 추가
    });

    try {
      final result = await _apiService.selectChunk(_currentSessionId!, selectedText);

      setState(() {
        _isLoading = false;
        _currentRecommendations = List<String>.from(result['topKChunks']);
      });

      _showResultSheet(); // 갱신된 정보로 다시 열기

    } catch (e) {
      print("선택 에러: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- 3. [New] 문장 완성 로직 ---
  void _handleComplete() {
    Navigator.pop(context); // 바텀 시트 닫기

    // 최종 문장 조합
    String finalSentence = _history.join(" ");

    // 화면 중앙에 크게 보여주기 (Dialog)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("완성된 문장"),
        content: Text(
          finalSentence.isEmpty ? "선택된 문장이 없습니다." : finalSentence,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 여기서 TTS로 읽어주기 기능 추가 가능
              Navigator.pop(context);
            },
            child: const Text("확인"),
          )
        ],
      ),
    );
  }

  // 결과창 띄우기
  void _showResultSheet() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResultSheet(
        storeName: _selectedStore,
        sttText: _currentSttText, // 전달
        history: _history,        // 전달
        recommendations: _currentRecommendations,
        onChunkSelected: _handleChunkSelect,
        onComplete: _handleComplete, // 전달
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("AAC Service", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
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
            child: Center(
              child: RecordButton(
                isRecording: _isRecording,
                isLoading: _isLoading,
                onTap: _handleRecording,
              ),
            ),
          )
        ],
      ),
    );
  }
}