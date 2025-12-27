import 'dart:async';

import 'package:flutter/material.dart';
import 'package:perplexity_clone/services/chat_web_service.dart';
import 'package:perplexity_clone/theme/colors.dart';

class AnswerSection extends StatefulWidget {
  const AnswerSection({super.key});

  @override
  State<AnswerSection> createState() => _AnswerSectionState();
}

class _AnswerSectionState extends State<AnswerSection> {
  late final StreamSubscription<Map<String, dynamic>> _subscription;
  bool _isLoading = true;
  String _answer = '';

  @override
  void initState() {
    super.initState();
    _subscription = ChatWebService().contentStream.listen(
      (data) {
        final chunk = data['data']?.toString() ?? '';
        if (chunk.isEmpty) return;
        setState(() {
          _answer += chunk;
          _isLoading = false;
        });
      },
      onError: (_) {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            /// HEADER
            Row(
              children: const [
                Icon(Icons.question_answer_outlined, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  'Answer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ANSWER CONTAINER
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: 100,
                maxHeight: screenHeight * 0.6,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),

              /// CONTENT
              child: _isLoading
                  ? Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        children: const [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                          Text('Waiting for response...'),
                        ],
                      ),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: LayoutBuilder(
                          builder: (context, innerConstraints) {
                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: innerConstraints.maxWidth,
                              ),
                              child: SelectableText(
                                _answer.isEmpty
                                    ? 'No answer received.'
                                    : _answer,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
