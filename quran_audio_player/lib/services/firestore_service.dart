import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/surah_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Future<void> addListeningSeconds(int seconds) async {
    final today = DateTime.now().toString().split(' ')[0];
    await _db.collection('users').doc(_uid).collection('stats').doc(today).set({
      'seconds': FieldValue.increment(seconds),
      'date': today,
    }, SetOptions(merge: true));
  }

  static Future<void> incrementPlayCount(Reciter r) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('playHistory')
        .doc(r.favouriteId)
        .set({
      ...r.toFirestore(),
      'count': FieldValue.increment(1),
      'lastPlayed': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, int>> getMonthStats() async {
    final now = DateTime.now();
    final prefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('stats')
        .where('date', isGreaterThanOrEqualTo: prefix)
        .get();
    return {for (var d in snap.docs) d.id: (d.data()['seconds'] as int? ?? 0)};
  }

  static Future<int> getTotalSeconds() async {
    final snap =
        await _db.collection('users').doc(_uid).collection('stats').get();
    int total = 0;
    for (var doc in snap.docs) {
      total += (doc.data()['seconds'] as int? ?? 0);
    }
    return total;
  }

  static Future<List<Map<String, dynamic>>> getTopTracks() async {
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('playHistory')
        .orderBy('count', descending: true)
        .limit(5)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  static Future<void> saveMonthlyGoal(int hours) async =>
      _db.collection('users').doc(_uid).update({'monthlyGoalHours': hours});

  /// Number of distinct surahs the user has played (based on playHistory docs).
  static Future<int> getTotalSurahsListened() async {
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('playHistory')
        .get();
    return snap.docs.length;
  }

  /// Total number of saved favourites.
  static Future<int> getFavouritesCount() async {
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('favourites')
        .get();
    return snap.docs.length;
  }

  /// All-time stats by date for computing averages.
  static Future<Map<String, int>> getAllStats() async {
    final snap =
        await _db.collection('users').doc(_uid).collection('stats').get();
    return {for (var d in snap.docs) d.id: (d.data()['seconds'] as int? ?? 0)};
  }

  static Stream<List<Reciter>> favouritesStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favourites')
        .snapshots()
        .map(
            (s) => s.docs.map((d) => Reciter.fromFirestore(d.data())).toList());
  }

  static Future<void> addFavourite(Reciter r) async => _db
      .collection('users')
      .doc(_uid)
      .collection('favourites')
      .doc(r.favouriteId)
      .set(r.toFirestore());

  static Future<void> removeFavourite(String id) async => _db
      .collection('users')
      .doc(_uid)
      .collection('favourites')
      .doc(id)
      .delete();
}
