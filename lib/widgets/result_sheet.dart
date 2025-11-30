import 'package:flutter/material.dart';
import '../constants/theme.dart';

class ResultSheet extends StatelessWidget {
  final String storeName;
  final String sttText;          // [추가] STT 원문
  final List<String> history;    // [추가] 지금까지 선택한 청크들
  final List<String> recommendations;
  final Function(String) onChunkSelected;
  final VoidCallback onComplete; // [추가] 완성 버튼 콜백

  const ResultSheet({
    super.key,
    required this.storeName,
    required this.sttText,
    required this.history,
    required this.recommendations,
    required this.onChunkSelected,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7, // 높이를 좀 더 키움
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들바
          Center(child: Container(width: 40, height: 4, color: Colors.grey[300])),
          const SizedBox(height: 20),

          // 1. 매장 이름
          Row(
            children: [
              const Icon(Icons.storefront, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(storeName, style: AppTextStyles.header),
            ],
          ),
          const SizedBox(height: 15),

          // 2. [New] 상태 표시 카드 (STT + 현재 문장)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // STT 원문
                Text("🗣️ 내가 말한 내용:", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(sttText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                // 현재 만들어진 문장
                Text("✍️ 만드는 중인 문장:", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                    history.isEmpty ? "(문장을 선택해주세요)" : history.join(" "),
                    style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. 추천 리스트
          const Text("다음에 올 말을 선택하세요", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: recommendations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onChunkSelected(recommendations[index]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                    ),
                    child: Text(recommendations[index], style: AppTextStyles.chunkTitle),
                  ),
                );
              },
            ),
          ),

          // 4. [New] 완성 버튼
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onComplete,
              child: const Text("문장 완성하기", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}