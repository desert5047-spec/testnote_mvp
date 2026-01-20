import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

import '../../data/repositories/test_repository.dart';

class TestRegisterPage extends StatefulWidget {
  const TestRegisterPage({
    super.key,
    required this.uid,
    required this.repo,
    required this.initialGrade,
    required this.initialSubject,
    required this.initialUnitTag,
  });

  final String uid;
  final TestRepository repo;

  final int initialGrade;
  final String initialSubject;
  final String? initialUnitTag;

  @override
  State<TestRegisterPage> createState() => _TestRegisterPageState();
}

class _TestRegisterPageState extends State<TestRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  late int grade;
  late String subject;
  String? unitTag;

  bool useScore = true;
  bool saving = false;

  // ✅ 写真2枚
  XFile? titlePhoto;
  XFile? fullPhoto;

  final subjects = const ['算数', '国語', '理科', '社会'];
  final grades = const [1, 2, 3, 4, 5, 6];

  final Map<String, List<String>> unitOptions = const {
    '1_算数': ['たし算', 'ひき算', 'くらべる', '時計', '図形', '文章題'],
    '2_算数': [
      'たし算(くり上がり)',
      'ひき算(くり下がり)',
      'かけ算',
      '時こくと時間',
      '長さ',
      'かさ',
      '図形',
      '文章題',
    ],
    '3_算数': ['わり算', '大きい数', '小数', '分数', '円と球', '重さ', '文章題'],
    '4_算数': ['わり算(筆算)', '小数', '分数', '面積', '角度', '折れ線グラフ', '文章題'],
    '5_算数': ['整数', '小数', '分数', '割合', '面積・体積', '速さ', 'グラフ', '文章題'],
    '6_算数': ['分数', '比例・反比例', '円の面積', '立体', '資料の調べ方', '文章題'],

    '1_国語': ['漢字', 'ひらがな・カタカナ', 'ことば', '読解(物語)', '読解(説明文)', '作文'],
    '2_国語': ['漢字', 'ことば', '読解(物語)', '読解(説明文)', '作文'],
    '3_国語': ['漢字', 'ことば', '文法', '読解(物語)', '読解(説明文)', '作文'],
    '4_国語': ['漢字', 'ことば', '文法', '読解(物語)', '読解(説明文)', '作文'],
    '5_国語': ['漢字', 'ことば', '文法', '要約', '読解(物語)', '読解(説明文)', '作文'],
    '6_国語': ['漢字', 'ことば', '文法', '要約', '読解(物語)', '読解(説明文)', '作文'],

    '3_理科': ['植物', '昆虫', '光と音', '磁石', '電気', '天気'],
    '4_理科': ['季節と生き物', '空気と水', '電気', '星', '天気'],
    '5_理科': ['天気', '植物', '動物', '流れる水', 'ふりこ', '電磁石'],
    '6_理科': ['人の体', '植物', '地層', '火山・地震', '電気', 'てこ'],

    '3_社会': ['地図・方位', '市のようす', 'くらしと仕事', '安全', '店・工場'],
    '4_社会': ['都道府県', '水・ごみ', 'くらし', '伝統', '災害'],
    '5_社会': ['地理(日本)', '農業', '工業', '貿易', '国土と環境'],
    '6_社会': ['歴史', '政治', '国際', '憲法', '選挙'],
  };

  List<String> _currentUnitOptions() {
    final key = '${grade}_$subject';
    return unitOptions[key] ?? const ['（単元なし）'];
  }

  void _ensureUnitValid() {
    final options = _currentUnitOptions();
    if (options.isEmpty || options.first == '（単元なし）') {
      unitTag = null;
      return;
    }
    if (unitTag == null || !options.contains(unitTag)) {
      unitTag = options.first;
    }
  }

  @override
  void initState() {
    super.initState();
    grade = widget.initialGrade;
    subject = widget.initialSubject;
    unitTag = widget.initialUnitTag;
    _ensureUnitValid();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _scoreCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTitlePhoto() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    setState(() => titlePhoto = x);
  }

  Future<void> _pickFullPhoto() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    setState(() => fullPhoto = x);
  }

  /// ✅ 画質を落として保存（リサイズ＆JPEG圧縮）
  Future<Uint8List> _compressJpeg(Uint8List inputBytes,
      {int maxWidth = 1280, int quality = 70}) async {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) return inputBytes;

    final resized = decoded.width > maxWidth
        ? img.copyResize(decoded, width: maxWidth)
        : decoded;

    final jpg = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(jpg);
  }

  Future<String> _uploadToStorage({
    required String uid,
    required String docId,
    required String kind, // "title" or "full"
    required Uint8List bytes,
  }) async {
    final path = 'users/$uid/tests/$docId/$kind.jpg';
    final ref = FirebaseStorage.instance.ref(path);

    final meta = SettableMetadata(contentType: 'image/jpeg');

    await ref.putData(bytes, meta);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (saving) return;
    if (!_formKey.currentState!.validate()) return;

    // ここは好み：2枚必須にするならチェック
    // if (titlePhoto == null || fullPhoto == null) { ... }

    setState(() => saving = true);
    try {
      final testName = _nameCtrl.text.trim();

      int? score;
      String? comment;
      if (useScore) {
        score = int.tryParse(_scoreCtrl.text.trim());
      } else {
        comment = _commentCtrl.text.trim();
      }

      // 1) 先にテストdocを作る（docId確保）
      final ref = await widget.repo.addTest(
        uid: widget.uid,
        grade: grade,
        subject: subject,
        unitTag: unitTag,
        testName: testName,
        score: score,
        comment: comment,
      );

      String? titleUrl;
      String? fullUrl;

      // 2) 写真があれば圧縮してアップロード
      if (titlePhoto != null) {
        final raw = await titlePhoto!.readAsBytes();
        final compressed = await _compressJpeg(raw, maxWidth: 1000, quality: 70);
        titleUrl = await _uploadToStorage(
          uid: widget.uid,
          docId: ref.id,
          kind: 'title',
          bytes: compressed,
        );
      }

      if (fullPhoto != null) {
        final raw = await fullPhoto!.readAsBytes();
        final compressed = await _compressJpeg(raw, maxWidth: 1600, quality: 70);
        fullUrl = await _uploadToStorage(
          uid: widget.uid,
          docId: ref.id,
          kind: 'full',
          bytes: compressed,
        );
      }

      // 3) URLをFirestoreへ紐づけ
      await widget.repo.attachPhotos(
        docId: ref.id,
        photoTitleUrl: titleUrl,
        photoFullUrl: fullUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存しました')),
      );

      Navigator.of(context).pop({
        'grade': grade,
        'subject': subject,
        'unitTag': unitTag,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitList = _currentUnitOptions();
    _ensureUnitValid();

    return Scaffold(
      appBar: AppBar(title: const Text('テストを追加')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('学年'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: grade,
                items: grades
                    .map((g) => DropdownMenuItem(value: g, child: Text('小$g')))
                    .toList(),
                onChanged: (v) => setState(() {
                  grade = v ?? grade;
                  _ensureUnitValid();
                }),
              ),
              const SizedBox(height: 16),

              const Text('教科'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: subject,
                items: subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() {
                  subject = v ?? subject;
                  _ensureUnitValid();
                }),
              ),
              const SizedBox(height: 16),

              const Text('単元（タグ）'),
              const SizedBox(height: 8),
              if (unitList.isEmpty || unitList.first == '（単元なし）')
                const Text('この学年・教科には単元候補がまだありません')
              else
                DropdownButtonFormField<String>(
                  value: unitTag,
                  items: unitList
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => unitTag = v),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              const SizedBox(height: 16),

              // ✅ 写真2枚
              const Text('写真（任意）'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : _pickTitlePhoto,
                      child: Text(titlePhoto == null ? '題名写真を選ぶ' : '題名：選択済み'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : _pickFullPhoto,
                      child: Text(fullPhoto == null ? '全体写真を選ぶ' : '全体：選択済み'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('テスト名'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: '例：かんじの試しがき / ひき算④',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'テスト名を入力してください' : null,
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: Text(useScore ? '点数で記録する' : 'コメントで記録する'),
                value: useScore,
                onChanged: (v) => setState(() => useScore = v),
              ),
              const SizedBox(height: 8),

              if (useScore) ...[
                const Text('点数'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _scoreCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '例：96',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final s = int.tryParse((v ?? '').trim());
                    if (s == null) return '点数を数字で入力してください';
                    if (s < 0 || s > 100) return '0〜100で入力してください';
                    return null;
                  },
                ),
              ] else ...[
                const Text('コメント'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '例：よくできた / 少しむずかしかった',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'コメントを入力してください' : null,
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: saving ? null : _save,
                child: Text(saving ? '保存中...' : '保存する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
