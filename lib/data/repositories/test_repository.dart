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

  /// ✅ docRef を返す（docId を使ってStorageパスを作る）
  Future<DocumentReference<Map<String, dynamic>>> addTest({
    required String uid,
    required int grade,
    required String subject,
    required String testName,
    String? unitTag,
    int? score,
    String? comment,
  }) async {
    final ref = await _col.add({
      'uid': uid,
      'grade': grade,
      'subject': subject,
      'testName': testName,
      'unitTag': unitTag,
      'score': score,
      'comment': comment,
      'createdAtClient': DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
      // 画像URLは後で update する
      'photoTitleUrl': null,
      'photoFullUrl': null,
    });
    return ref;
  }

  Future<void> attachPhotos({
    required String docId,
    required String? photoTitleUrl,
    required String? photoFullUrl,
  }) async {
    await _col.doc(docId).update({
      'photoTitleUrl': photoTitleUrl,
      'photoFullUrl': photoFullUrl,
    });
  }
}
