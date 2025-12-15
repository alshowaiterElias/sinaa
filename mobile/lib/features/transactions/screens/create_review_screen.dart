import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sinaa_mobile/config/theme.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/repositories/review_repository.dart';

class CreateReviewScreen extends ConsumerStatefulWidget {
  final int transactionId;
  final int productId;

  const CreateReviewScreen({
    super.key,
    required this.transactionId,
    required this.productId,
  });

  @override
  ConsumerState<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends ConsumerState<CreateReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final isRtl = context.isRtl;

    if (_rating == 0) {
      setState(() {
        _error = isRtl ? 'يرجى اختيار تقييم' : 'Please select a rating';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(reviewRepositoryProvider).createReview(
            transactionId: widget.transactionId,
            productId: widget.productId,
            rating: _rating,
            comment: _commentController.text.isEmpty
                ? null
                : _commentController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRtl
                ? 'تم إرسال التقييم بنجاح'
                : 'Review submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'إضافة تقييم' : 'Add Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product being rated
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_bag,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRtl
                                ? 'المنتج الذي تقيمه'
                                : 'Product you are rating',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isRtl
                                ? 'تقييم المنتج #${widget.productId}'
                                : 'Product #${widget.productId}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rating section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      isRtl ? 'ما هو تقييمك؟' : 'How would you rate?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = starIndex),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              starIndex <= _rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 48,
                              color: starIndex <= _rating
                                  ? Colors.amber
                                  : Colors.grey[400],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRatingText(isRtl),
                      style: TextStyle(
                        color: _rating > 0 ? Colors.amber[800] : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Comment section
            Text(
              isRtl ? 'تعليق (اختياري)' : 'Comment (optional)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: isRtl
                    ? 'شارك تجربتك مع الآخرين...'
                    : 'Share your experience with others...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isRtl ? 'إرسال التقييم' : 'Submit Review',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(bool isRtl) {
    switch (_rating) {
      case 1:
        return isRtl ? 'سيئ جداً' : 'Very Poor';
      case 2:
        return isRtl ? 'سيئ' : 'Poor';
      case 3:
        return isRtl ? 'متوسط' : 'Average';
      case 4:
        return isRtl ? 'جيد' : 'Good';
      case 5:
        return isRtl ? 'ممتاز' : 'Excellent';
      default:
        return isRtl ? 'اختر تقييماً' : 'Tap to rate';
    }
  }
}
