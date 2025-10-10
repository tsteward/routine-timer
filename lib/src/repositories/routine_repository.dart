import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routine_completion.dart';
import '../models/routine_state.dart';
import '../services/auth_service.dart';

/// Repository for persisting and loading routine data from Firebase Firestore.
/// Each user's routine is stored in a separate document: routines/{userId}
class RoutineRepository {
  RoutineRepository({FirebaseFirestore? firestore, AuthService? authService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  /// Collection name for routines in Firestore
  static const String _routinesCollection = 'routines';
  
  /// Collection name for completion data in Firestore
  static const String _completionsCollection = 'completions';

  /// Reference to the current user's routine document
  /// Returns null if user is not signed in
  DocumentReference<Map<String, dynamic>>? get _userRoutineDoc {
    final userId = _authService.currentUserId;
    if (userId == null) return null;

    return _firestore.collection(_routinesCollection).doc(userId);
  }

  /// Reference to the current user's completions collection
  /// Returns null if user is not signed in
  CollectionReference<Map<String, dynamic>>? get _userCompletionsCollection {
    final userId = _authService.currentUserId;
    if (userId == null) return null;

    return _firestore
        .collection(_completionsCollection)
        .doc(userId)
        .collection('sessions');
  }

  /// Saves the entire routine state to Firestore for current user.
  /// Returns true if successful, false otherwise.
  Future<bool> saveRoutine(RoutineStateModel routine) async {
    try {
      final doc = _userRoutineDoc;
      if (doc == null) {
        return false;
      }

      await doc.set(routine.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Loads the routine state from Firestore for current user.
  /// Returns null if document doesn't exist or on error.
  Future<RoutineStateModel?> loadRoutine() async {
    try {
      final doc = _userRoutineDoc;
      if (doc == null) {
        return null;
      }

      final snapshot = await doc.get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      return RoutineStateModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  /// Stream of routine updates from Firestore (for real-time sync)
  /// Returns null initially if document doesn't exist.
  Stream<RoutineStateModel?> watchRoutine() {
    final doc = _userRoutineDoc;
    if (doc == null) {
      return Stream.value(null);
    }

    return doc.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      try {
        return RoutineStateModel.fromMap(data);
      } catch (e) {
        return null;
      }
    });
  }

  /// Deletes the current user's routine from Firestore
  Future<bool> deleteRoutine() async {
    try {
      final doc = _userRoutineDoc;
      if (doc == null) {
        return false;
      }

      await doc.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Saves completion data to Firestore for the current user.
  /// Creates a new document with timestamp as ID for easy querying.
  /// Returns true if successful, false otherwise.
  Future<bool> saveCompletion(RoutineCompletionModel completion) async {
    try {
      final collection = _userCompletionsCollection;
      if (collection == null) {
        return false;
      }

      // Use timestamp as document ID for easy chronological ordering
      final docId = completion.completedAt.millisecondsSinceEpoch.toString();
      
      await collection.doc(docId).set(completion.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Loads the most recent completion data from Firestore.
  /// Returns null if no completions exist or on error.
  Future<RoutineCompletionModel?> loadLatestCompletion() async {
    try {
      final collection = _userCompletionsCollection;
      if (collection == null) {
        return null;
      }

      final snapshot = await collection
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data();
      return RoutineCompletionModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  /// Loads completion history from Firestore.
  /// Returns list ordered by completion date (most recent first).
  /// [limit] specifies maximum number of completions to return.
  Future<List<RoutineCompletionModel>> loadCompletionHistory({
    int limit = 10,
  }) async {
    try {
      final collection = _userCompletionsCollection;
      if (collection == null) {
        return [];
      }

      final snapshot = await collection
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RoutineCompletionModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Deletes all completion data for the current user
  Future<bool> deleteAllCompletions() async {
    try {
      final collection = _userCompletionsCollection;
      if (collection == null) {
        return false;
      }

      final snapshot = await collection.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }
}
