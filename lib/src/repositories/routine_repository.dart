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

  /// Collection name for completion history in Firestore
  static const String _completionsCollection = 'completions';

  /// Reference to the current user's routine document
  /// Returns null if user is not signed in
  DocumentReference<Map<String, dynamic>>? get _userRoutineDoc {
    final userId = _authService.currentUserId;
    if (userId == null) return null;

    return _firestore.collection(_routinesCollection).doc(userId);
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

  /// Saves routine completion data to Firestore.
  /// Creates a new document in the completions subcollection for the user.
  /// Returns true if successful, false otherwise.
  Future<bool> saveCompletionData(RoutineCompletionModel completion) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        return false;
      }

      // Save to user's completions subcollection
      await _firestore
          .collection(_routinesCollection)
          .doc(userId)
          .collection(_completionsCollection)
          .add(completion.toMap());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Loads completion history for the current user.
  /// Returns a list of completions ordered by most recent first.
  Future<List<RoutineCompletionModel>> loadCompletionHistory({
    int limit = 30,
  }) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection(_routinesCollection)
          .doc(userId)
          .collection(_completionsCollection)
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
}
