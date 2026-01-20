import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/test_record.dart';

class TestRepository {
  TestRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('tests');

  Stream<List<TestRecord>> watchLatest({
    required String uid,
    int limit = 50,
  }) {
    return _col
        .where('uid', isEqualTo: uid)
        .orderBy('createdAtClient', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TestRecord.fromDoc(d.id, d.data()))
            .toList());
  }

  Future<void> addTest({
    required String uid,
    required int grade,
    required String subject,
    required String testName,
    String? unitTag, // ✅ これを追加
    int? score,
    String? comment,
  }) async {
    await _col.add({
      'uid': uid,
      'grade': grade,
      'subject': subject,
      'testName': testName,
      'unitTag': unitTag, // ✅ これを追加
      'score': score,
      'comment': comment,
      'createdAtClient': DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
