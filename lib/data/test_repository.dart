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
    String? unitTag, // ✅追加
    int? score,
    String? comment,
  }) async {
    await _col.add({
      'uid': uid,
      'grade': grade,
      'subject': subject,
      'testName': testName,
      'unitTag': unitTag, // ✅追加
      'score': score,
      'comment': comment,

      // 並び順用：即時に必ず入る
      'createdAtClient': DateTime.now().millisecondsSinceEpoch,

      // 正式な時刻（サーバー確定）
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
