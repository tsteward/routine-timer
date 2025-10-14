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

  /// Collection name for routine completions in Firestore
  static const String _completionsCollection = 'routine_completions';

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

  /// Saves completion data to Firestore for analytics
  /// Creates a new document in the completions subcollection
  Future<bool> saveCompletion(RoutineCompletion completion) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        return false;
      }

      // Store completions in a subcollection under the user's document
      await _firestore
          .collection(_completionsCollection)
          .doc(userId)
          .collection('history')
          .add(completion.toMap());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Loads completion history for the current user
  Future<List<RoutineCompletion>> loadCompletionHistory({int? limit}) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        return [];
      }

      var query = _firestore
          .collection(_completionsCollection)
          .doc(userId)
          .collection('history')
          .orderBy('completedAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => RoutineCompletion.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
