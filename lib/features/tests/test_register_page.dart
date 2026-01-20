import 'package:flutter/material.dart';
import '../../data/repositories/test_repository.dart';

class TestRegisterPage extends StatefulWidget {
  const TestRegisterPage({
    super.key,
    required this.uid,
    required this.repo,
  });

  final String uid;
  final TestRepository repo;

  @override
  State<TestRegisterPage> createState() => _TestRegisterPageState();
}

class _TestRegisterPageState extends State<TestRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  int grade = 2;
  String subject = '算数';

  /// ✅ 単元タグ（選択）
  String? unitTag;

  bool useScore = true;
  bool saving = false;

  final subjects = const ['算数', '国語', '理科', '社会'];
  final grades = const [1, 2, 3, 4, 5, 6];

  // ✅ 学年×教科で候補が変わる単元セット（まずはMVP用の粒度）
  final Map<String, List<String>> unitOptions = const {
    // --- 算数 ---
    '1_算数': [
      'たし算',
      'ひき算',
      'くらべる',
      '時計',
      '図形',
      '文章題',
    ],
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
    '3_算数': [
      'わり算',
      '大きい数',
      '小数',
      '分数',
      '円と球',
      '重さ',
      '文章題',
    ],
    '4_算数': [
      'わり算(筆算)',
      '小数',
      '分数',
      '面積',
      '角度',
      '折れ線グラフ',
      '文章題',
    ],
    '5_算数': [
      '整数',
      '小数',
      '分数',
      '割合',
      '面積・体積',
      '速さ',
      'グラフ',
      '文章題',
    ],
    '6_算数': [
      '分数',
      '比例・反比例',
      '円の面積',
      '立体',
      '資料の調べ方',
      '文章題',
    ],

    // --- 国語 ---
    '1_国語': ['漢字', 'ひらがな・カタカナ', 'ことば', '読解(物語)', '読解(説明文)', '作文'],
    '2_国語': ['漢字', 'ことば', '読解(物語)', '読解(説明文)', '作文'],
    '3_国語': ['漢字', 'ことば', '文法', '読解(物語)', '読解(説明文)', '作文'],
    '4_国語': ['漢字', 'ことば', '文法', '読解(物語)', '読解(説明文)', '作文'],
    '5_国語': ['漢字', 'ことば', '文法', '要約', '読解(物語)', '読解(説明文)', '作文'],
    '6_国語': ['漢字', 'ことば', '文法', '要約', '読解(物語)', '読解(説明文)', '作文'],

    // --- 理科 ---
    '3_理科': ['植物', '昆虫', '光と音', '磁石', '電気', '天気'],
    '4_理科': ['季節と生き物', '空気と水', '電気', '星', '天気'],
    '5_理科': ['天気', '植物', '動物', '流れる水', 'ふりこ', '電磁石'],
    '6_理科': ['人の体', '植物', '地層', '火山・地震', '電気', 'てこ'],

    // --- 社会 ---
    '3_社会': ['地図・方位', '市のようす', 'くらしと仕事', '安全', '店・工場'],
    '4_社会': ['都道府県', '水・ごみ', 'くらし', '伝統', '災害'],
    '5_社会': ['地理(日本)', '農業', '工業', '貿易', '国土と環境'],
    '6_社会': ['歴史', '政治', '国際', '憲法', '選挙'],
  };

  List<String> _currentUnitOptions() {
    final key = '${grade}_$subject';
    return unitOptions[key] ?? const ['（単元なし）'];
  }

  void _resetUnitIfNeeded() {
    final options = _currentUnitOptions();
    if (options.isEmpty) {
      unitTag = null;
      return;
    }
    if (unitTag == null || !options.contains(unitTag)) {
      // 候補にない場合は先頭に合わせる（単元なしなら null）
      unitTag = options.first == '（単元なし）' ? null : options.first;
    }
  }

  @override
  void initState() {
    super.initState();
    _resetUnitIfNeeded();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _scoreCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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

      await widget.repo.addTest(
        uid: widget.uid,
        grade: grade,
        subject: subject,
        unitTag: unitTag, // ✅保存
        testName: testName,
        score: score,
        comment: comment,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitList = _currentUnitOptions();
    _resetUnitIfNeeded();

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
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text('小$g'),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    grade = v ?? 2;
                    _resetUnitIfNeeded();
                  });
                },
              ),
              const SizedBox(height: 16),

              const Text('教科'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: subject,
                items: subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    subject = v ?? '算数';
                    _resetUnitIfNeeded();
                  });
                },
              ),
              const SizedBox(height: 16),

              const Text('単元（タグ）'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: unitTag ?? (unitList.first == '（単元なし）' ? null : unitList.first),
                items: unitList.first == '（単元なし）'
                    ? const []
                    : unitList
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                onChanged: (v) => setState(() => unitTag = v),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                hint: const Text('単元を選択'),
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
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'テスト名を入力してください';
                  }
                  return null;
                },
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
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'コメントを入力してください';
                    }
                    return null;
                  },
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
