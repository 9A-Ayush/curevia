import 'package:flutter/material.dart';
import '../utils/firestore_index_helper.dart';
import '../constants/app_colors.dart';

/// Banner widget that shows Firestore index building status
class IndexStatusBanner extends StatefulWidget {
  final String userId;
  final Widget child;

  const IndexStatusBanner({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  State<IndexStatusBanner> createState() => _IndexStatusBannerState();
}

class _IndexStatusBannerState extends State<IndexStatusBanner> {
  bool _indexesReady = true;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkIndexStatus();
  }

  Future<void> _checkIndexStatus() async {
    try {
      final isReady = await FirestoreIndexHelper.areMoodIndexesReady(widget.userId);
      if (mounted) {
        setState(() {
          _indexesReady = isReady;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _indexesReady = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show banner if indexes are not ready
        if (!_indexesReady && !_isChecking)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border(
                bottom: BorderSide(
                  color: Colors.orange[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setting up mood tracking...',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Database indexes are building. Full features available shortly.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => FirestoreIndexHelper.showIndexStatusDialog(
                    context, 
                    widget.userId,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Details',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Simple index status indicator for smaller spaces
class IndexStatusIndicator extends StatefulWidget {
  final String userId;

  const IndexStatusIndicator({
    super.key,
    required this.userId,
  });

  @override
  State<IndexStatusIndicator> createState() => _IndexStatusIndicatorState();
}

class _IndexStatusIndicatorState extends State<IndexStatusIndicator> {
  bool _indexesReady = true;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkIndexStatus();
  }

  Future<void> _checkIndexStatus() async {
    try {
      final isReady = await FirestoreIndexHelper.areMoodIndexesReady(widget.userId);
      if (mounted) {
        setState(() {
          _indexesReady = isReady;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _indexesReady = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_indexesReady) {
      return Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: 16,
      );
    }

    return GestureDetector(
      onTap: () => FirestoreIndexHelper.showIndexStatusDialog(
        context, 
        widget.userId,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Setting up',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}