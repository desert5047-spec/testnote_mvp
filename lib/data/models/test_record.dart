import 'package:cloud_firestore/cloud_firestore.dart';

class TestRecord {
  final String id;
  final String uid;

  /// 学年（1〜6）
  final int? grade;

  final String subject;

  /// 単元タグ
  final String? unitTag;

  final String testName;
  final int? score;
  final String? comment;

  /// サーバー時刻
  final DateTime? createdAt;

  /// 並び順用（即時）
  final int? createdAtClient;

  /// ✅ 写真URL（StorageのDownload URL）
  final String? photoTitleUrl;
  final String? photoFullUrl;

  TestRecord({
    required this.id,
    required this.uid,
    this.grade,
    required this.subject,
    this.unitTag,
    required this.testName,
    this.score,
    this.comment,
    this.createdAt,
    this.createdAtClient,
    this.photoTitleUrl,
    this.photoFullUrl,
  });

  static TestRecord fromDoc(String id, Map<String, dynamic> data) {
    DateTime? createdAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    }

    final rawScore = data['score'];
    final int? score = rawScore is int
        ? rawScore
        : int.tryParse((rawScore ?? '').toString());

    final rawClientAt = data['createdAtClient'];
    final int? createdAtClient = rawClientAt is int
        ? rawClientAt
        : int.tryParse((rawClientAt ?? '').toString());

    final rawGrade = data['grade'];
    final int? grade =
        rawGrade is int ? rawGrade : int.tryParse((rawGrade ?? '').toString());

    final String? unitTag =
        data['unitTag'] == null ? null : data['unitTag'].toString();

    final String? photoTitleUrl = data['photoTitleUrl'] == null
        ? null
        : data['photoTitleUrl'].toString();

    final String? photoFullUrl = data['photoFullUrl'] == null
        ? null
        : data['photoFullUrl'].toString();

    return TestRecord(
      id: id,
      uid: (data['uid'] ?? '').toString(),
      grade: grade,
      subject: (data['subject'] ?? '').toString(),
      unitTag: unitTag,
      testName: (data['testName'] ?? '').toString(),
      score: score,
      comment: data['comment'] == null ? null : data['comment'].toString(),
      createdAt: createdAt,
      createdAtClient: createdAtClient,
      photoTitleUrl: photoTitleUrl,
      photoFullUrl: photoFullUrl,
    );
  }
}
