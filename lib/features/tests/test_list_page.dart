import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/test_repository.dart';
import '../../data/models/test_record.dart';
import 'test_register_page.dart';

class TestListPage extends StatefulWidget {
  const TestListPage({super.key});

  @override
  State<TestListPage> createState() => _TestListPageState();
}

class _TestListPageState extends State<TestListPage> {
  final repo = TestRepository();

  int lastGrade = 2;
  String lastSubject = '算数';
  String? lastUnitTag;

  Future<String> _ensureAnonUid() async {
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    if (current != null) return current.uid;
    final cred = await auth.signInAnonymously();
    return cred.user!.uid;
  }

  String _formatDateFromClientMs(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.month}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  void _openPhotoViewer(BuildContext context, TestRecord t) {
    final url = (t.photoFullUrl?.isNotEmpty == true)
        ? t.photoFullUrl!
        : (t.photoTitleUrl?.isNotEmpty == true ? t.photoTitleUrl! : null);

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真がありません')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('画像の読み込みに失敗しました'),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _thumb(TestRecord t) {
    final thumbUrl =
        (t.photoTitleUrl?.isNotEmpty == true) ? t.photoTitleUrl! : null;

    if (thumbUrl == null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black12,
        ),
        child: const Icon(Icons.description_outlined),
      );
    }
    

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        thumbUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black12,
          ),
          child: const Icon(Icons.broken_image_outlined),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black12,
            ),
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
  IconData _subjectIcon(String subject) {
  switch (subject) {
    case '国語':
      return Icons.menu_book;
    case '算数':
      return Icons.calculate;
    case '理科':
      return Icons.science;
    case '社会':
      return Icons.public;
    case '英語':
      return Icons.language;
    default:
      return Icons.description;
  }
}


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _ensureAnonUid(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final uid = snap.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('テスト記録'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TestRegisterPage(
                        uid: uid,
                        repo: repo,
                        initialGrade: lastGrade,
                        initialSubject: lastSubject,
                        initialUnitTag: lastUnitTag,
                      ),
                    ),
                  );

                  if (result is Map) {
                    setState(() {
                      lastGrade = (result['grade'] is int)
                          ? result['grade'] as int
                          : lastGrade;
                      lastSubject =
                          (result['subject']?.toString() ?? lastSubject);
                      lastUnitTag = result['unitTag'] == null
                          ? null
                          : result['unitTag'].toString();
                    });
                  }
                },
              ),
            ],
          ),
          body: StreamBuilder<List<TestRecord>>(
            stream: repo.watchLatest(uid: uid),
            builder: (context, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (s.hasError) {
                return Center(
                  child:
                      Text('読み込みエラー\n${s.error}', textAlign: TextAlign.center),
                );
              }

              final items = s.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Text('まだ記録がありません。\n右上の＋から追加できます。',
                      textAlign: TextAlign.center),
                );
              }

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final t = items[i];

                  final scoreText = (t.score != null)
                      ? '${t.score}点'
                      : (t.comment?.isNotEmpty == true ? t.comment! : '—');

                  final gradeText = (t.grade != null) ? '小${t.grade}' : '小?';
                  final unit = (t.unitTag != null && t.unitTag!.isNotEmpty)
                      ? t.unitTag!
                      : '（未設定）';
                  final dateText = _formatDateFromClientMs(t.createdAtClient);

                  final hasPhoto =
    (t.photoTitleUrl?.isNotEmpty ?? false) || (t.photoFullUrl?.isNotEmpty ?? false);

return ListTile(
  leading: CircleAvatar(
    child: Icon(_subjectIcon(t.subject)),
  ),
  title: Text('$gradeText｜${t.subject}｜$unit｜${t.testName}'),
  subtitle: Text(dateText.isEmpty ? scoreText : '$scoreText  ・  $dateText'),
  trailing: hasPhoto
      ? IconButton(
          icon: const Icon(Icons.image_outlined),
          onPressed: () => _openPhotoViewer(context, t),
        )
      : null,
  onTap: () {},
);


                },
              );
            },
          ),
        );
      },
    );
  }
}
