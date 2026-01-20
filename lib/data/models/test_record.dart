import 'package:cloud_firestore/cloud_firestore.dart';

class TestRecord {
  final String id;
  final String uid;

  /// 学年（1〜6）
  final int? grade;

  final String subject;

  /// ✅ 単元タグ（例：かけ算 / ひき算(くり下がり) / 天気 など）
  final String? unitTag;

  final String testName;
  final int? score;
  final String? comment;

  /// サーバー時刻（確定は少し遅れる）
  final DateTime? createdAt;

  /// 並び順用（必ず即時に入る）
  final int? createdAtClient;

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
  });

  static TestRecord fromDoc(String id, Map<String, dynamic> data) {
    // serverTimestamp の安全な変換
    DateTime? createdAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    }

    // score は int / String どちらでも受ける
    final rawScore = data['score'];
    final int? score = rawScore is int
        ? rawScore
        : int.tryParse((rawScore ?? '').toString());

    // createdAtClient
    final rawClientAt = data['createdAtClient'];
    final int? createdAtClient = rawClientAt is int
        ? rawClientAt
        : int.tryParse((rawClientAt ?? '').toString());

    // grade
    final rawGrade = data['grade'];
    final int? grade =
        rawGrade is int ? rawGrade : int.tryParse((rawGrade ?? '').toString());

    // unitTag
    final String? unitTag =
        data['unitTag'] == null ? null : data['unitTag'].toString();

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
    );
  }
}
