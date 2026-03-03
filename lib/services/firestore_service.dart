import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_history_model.dart';

import 'local_cache_service.dart';

class FirestoreService {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  bool _isAvailable = false;

  FirestoreService() {
    _init();
  }

  void _init() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _auth = FirebaseAuth.instance;
        _isAvailable = true;
        
        // Enable offline persistence only if available
        _firestore?.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }
    } catch (e) {
      debugPrint('Firebase not initialized or not available: $e');
      _isAvailable = false;
    }
  }

  // Get current user ID
  String getCurrentUserId() {
    if (!_isAvailable) return 'offline_user';
    return _auth?.currentUser?.uid ?? 'anonymous';
  }

  // Save AI tool result
  Future<void> saveAIResult(AIHistory history) async {
    // 1. Always save to Local cache (in-memory/persistent SharedPreferences backup)
    await LocalCacheService.instance.saveHistory(history);

    // 2. Try saving to Firestore if available
    // 2. Try saving to Firestore if available AND user is logged in
    if (_isAvailable && _firestore != null && _auth?.currentUser != null) {
      try {
        final data = history.toFirestore();
        data['userId'] = getCurrentUserId();
        await _firestore?.collection('ai_history').add(data);
      } catch (e) {
        debugPrint('Error saving to Firestore: $e');
        // Silent fail, data is safe in Local DB
      }
    }
  }

  // Get user's AI history
  Stream<List<AIHistory>> getUserHistoryStream() {
    // If we have Firestore and the user is authenticated, prefer it (for sync across devices)
    if (_isAvailable && _firestore != null && _auth?.currentUser != null) {
      return _firestore!
          .collection('ai_history')
          .where('userId', isEqualTo: getCurrentUserId())
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => AIHistory.fromFirestore(doc)).toList())
          .handleError((e) {
            debugPrint("Firestore Error: $e. Falling back to local.");
            // On error, we could return local stream, but handling stream errors 
            // to switch streams is complex. 
            // For now, if Firestore fails initially, _isAvailable checks usually prevent this path.
            return [];
          });
    }
    
    // Fallback: Return local history
    return Stream.fromFuture(LocalCacheService.instance.getHistory());
  }

  // Delete a history entry
  Future<void> deleteHistory(String docId) async {
    // Delete from Local cache
    await LocalCacheService.instance.deleteHistory(docId);

    // Delete from Cloud
    if (_isAvailable && _firestore != null) {
       try {
         // Note: If docId came from LocalDB, it might not exist in Firestore 
         // if it wasn't synced. We attempt delete anyway.
         // Real sync requires consistent IDs, which is out of scope for this quick fix.
         // We assume IDs might diverge, so this is "Best Effort" deletion.
         await _firestore?.collection('ai_history').doc(docId).delete();
       } catch (e) {
         debugPrint("Error deleting from Firestore: $e");
       }
    }
  }

  // Clear all user history
  Future<void> clearAllHistory() async {
    // Clear Local cache
    await LocalCacheService.instance.clearHistory();

    // Clear Cloud
    if (_isAvailable && _firestore != null) {
      try {
        final query = await _firestore!
            .collection('ai_history')
            .where('userId', isEqualTo: getCurrentUserId())
            .get();
        final batch = _firestore!.batch();
        for (var doc in query.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error clearing history: $e');
      }
    }
  }

  // Get tool usage statistics
  Future<Map<String, int>> getToolUsageStats() async {
    if (!_isAvailable || _firestore == null || _auth?.currentUser == null) {
      // Offline stats logic
      final history = await LocalCacheService.instance.getHistory();
      Map<String, int> stats = {};
      for (var item in history) {
        stats[item.toolName] = (stats[item.toolName] ?? 0) + 1;
      }
      return stats;
    }
    
    try {
      final query = await _firestore!
          .collection('ai_history')
          .where('userId', isEqualTo: getCurrentUserId())
          .get();

      Map<String, int> stats = {};
      for (var doc in query.docs) {
        final data = doc.data();
        final toolName = data['toolName'];
        if (toolName != null) {
          stats[toolName] = (stats[toolName] ?? 0) + 1;
        }
      }
      return stats;
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return {};
    }
  }
}
