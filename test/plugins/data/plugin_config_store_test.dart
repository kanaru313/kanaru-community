import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_values.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';

import '../../database/support/test_db.dart';
import 'store_test_support.dart';

Map<String, Object?> _fields() => {
  'token': {
    'title': 'Token',
    'mode': 'input',
    'format': 'text',
    'required': true,
  },
  'count': {
    'title': 'Count',
    'mode': 'input',
    'format': 'integer',
    'min': 1,
    'max': 10,
    'default': 3,
  },
  'mode': {
    'title': 'Mode',
    'mode': 'select',
    'options': [
      {'value': 'a', 'title': 'A'},
      {'value': 'b', 'title': 'B'},
    ],
    'default': 'a',
  },
  'tags': {
    'title': 'Tags',
    'mode': 'select',
    'format': 'multiple',
    'options': [
      {'value': 'x', 'title': 'X'},
      {'value': 'y', 'title': 'Y'},
    ],
  },
  'model': {
    'title': 'Model',
    'mode': 'select',
    'custom': true,
    'options': [
      {'value': 'fast', 'title': 'Fast'},
      {'value': 'smart', 'title': 'Smart'},
    ],
    'default': 'fast',
  },
  'on': {'title': 'On', 'mode': 'toggle', 'default': false},
  'hosts': {'title': 'Hosts', 'mode': 'list', 'format': 'url'},
  'names': {'title': 'Names', 'mode': 'map'},
};

void main() {
  late AppDatabase db;
  late PluginRows rows;
  late PluginConfigStore store;
  final id = testInstallId();
  var now = 1000;

  Future<void> install([
    Map<String, Object?>? fields,
    String dir = 'v3-1',
  ]) async {
    await rows.installOrRevive(
      id,
      draftOf(packageOf(manifestWith(fields ?? _fields())), dir),
      const PluginSource.file('demo.zip'),
    );
  }

  setUp(() async {
    db = openTestDb();
    now = 1000;
    rows = PluginRows(db, clock: () => now++);
    store = PluginConfigStore(db, rows);
    await install();
  });
  tearDown(() => db.close());

  group('setValue', () {
    test('stores a fitting value of every mode', () async {
      expect(await store.setValue(id, 'token', 'k-1'), ConfigWrite.written);
      expect(await store.setValue(id, 'count', 7), ConfigWrite.written);
      expect(await store.setValue(id, 'mode', 'b'), ConfigWrite.written);
      expect(await store.setValue(id, 'tags', ['x', 'y']), ConfigWrite.written);
      expect(await store.setValue(id, 'on', true), ConfigWrite.written);
      expect(
        await store.setValue(id, 'hosts', ['https://a.example.com']),
        ConfigWrite.written,
      );
      expect(
        await store.setValue(id, 'names', {'a': 'b'}),
        ConfigWrite.written,
      );
      expect((await store.read(id)).values, {
        'token': 'k-1',
        'count': 7,
        'mode': 'b',
        'tags': ['x', 'y'],
        'on': true,
        'hosts': ['https://a.example.com'],
        'names': {'a': 'b'},
      });
    });

    test(
      'an unknown key, a removed plugin or a missing one is unknownKey',
      () async {
        expect(await store.setValue(id, 'nope', 'x'), ConfigWrite.unknownKey);
        expect(
          await store.setValue(testInstallId(5), 'token', 'x'),
          ConfigWrite.unknownKey,
        );
        await rows.remove(id);
        expect(await store.setValue(id, 'token', 'x'), ConfigWrite.unknownKey);
        expect(await db.select(db.pluginData).get(), isEmpty);
      },
    );

    test(
      'a value that does not fit is invalidValue and nothing changes',
      () async {
        await store.setValue(id, 'count', 5);
        expect(await store.setValue(id, 'count', 11), ConfigWrite.invalidValue);
        expect(
          await store.setValue(id, 'count', '5'),
          ConfigWrite.invalidValue,
        );
        expect(
          await store.setValue(id, 'count', 2.5),
          ConfigWrite.invalidValue,
        );
        expect(await store.setValue(id, 'mode', 'z'), ConfigWrite.invalidValue);
        expect(
          await store.setValue(id, 'tags', ['x', 'x']),
          ConfigWrite.invalidValue,
        );
        expect(await store.setValue(id, 'on', 'yes'), ConfigWrite.invalidValue);
        expect(
          await store.setValue(id, 'hosts', ['http://a.example.com']),
          ConfigWrite.invalidValue,
        );
        expect(
          await store.setValue(id, 'names', {'': 'x'}),
          ConfigWrite.invalidValue,
        );
        expect((await store.read(id)).values, {'count': 5});
      },
    );

    test(
      'null or an empty string removes the value; an empty list is a value',
      () async {
        await store.setValue(id, 'token', 'k');
        await store.setValue(id, 'tags', ['x']);
        expect(await store.setValue(id, 'token', ''), ConfigWrite.written);
        expect(await store.setValue(id, 'tags', null), ConfigWrite.written);
        expect((await store.read(id)).values, isEmpty);
        await store.setValue(id, 'hosts', <String>[]);
        expect((await store.read(id)).values, {'hosts': <String>[]});
      },
    );

    test('over 64 KiB is tooLarge and keeps the old values', () async {
      await store.setValue(id, 'token', 'k');
      final big = {for (var i = 0; i < 25; i++) 'key$i': 'x' * 2000};
      final fields = {
        'names': {'title': 'N', 'mode': 'map'},
        'token': {'title': 'T', 'mode': 'input'},
        'a': {'title': 'A', 'mode': 'map'},
        'b': {'title': 'B', 'mode': 'map'},
      };
      await rows.switchPackage(
        id,
        draftOf(packageOf(manifestWith(fields)), 'v3-2'),
      );
      expect(await store.setValue(id, 'names', big), ConfigWrite.written);
      expect(await store.setValue(id, 'a', big), ConfigWrite.tooLarge);
      expect((await store.read(id)).values.keys, {'token', 'names'});
    });

    test(
      'a value passes against the effective field of a custom select',
      () async {
        expect(
          await store.setValue(id, 'model', 'mine'),
          ConfigWrite.invalidValue,
        );
        await store.addCustomChoice(id, 'model', 'mine');
        await store.setValue(id, 'model', 'fast');
        expect(await store.setValue(id, 'model', 'mine'), ConfigWrite.written);
        expect((await store.read(id)).values['model'], 'mine');
      },
    );
  });

  group('configForRun', () {
    test('stored, then default, then absent', () async {
      await store.setValue(id, 'token', 'k');
      await store.setValue(id, 'mode', 'b');
      final run = await store.configForRun(id);
      expect(run['token'], 'k');
      expect(run['mode'], 'b');
      expect(run['count'], 3);
      expect(run['on'], false);
      expect(run['model'], 'fast');
      expect(run.containsKey('tags'), isFalse);
      expect(run.containsKey('hosts'), isFalse);
    });

    test(
      'a stored value that no longer fits is absent, not the default',
      () async {
        await store.setValue(id, 'mode', 'b');
        // A later form without option b: the stored value is left in place.
        final fields = _fields();
        (fields['mode']! as Map)['options'] = [
          {'value': 'a', 'title': 'A'},
        ];
        await rows.switchPackage(
          id,
          draftOf(packageOf(manifestWith(fields)), 'v3-2'),
        );
        final run = await store.configForRun(id);
        expect(run.containsKey('mode'), isFalse);
      },
    );

    test(
      'a user choice reaches the script; a removed plugin reads empty',
      () async {
        await store.addCustomChoice(id, 'model', 'mine');
        expect((await store.configForRun(id))['model'], 'mine');
        await rows.remove(id);
        expect(await store.configForRun(id), isEmpty);
      },
    );

    test('collections are copies', () async {
      await store.setValue(id, 'tags', ['x']);
      final first = await store.configForRun(id);
      (first['tags']! as List).add('boom');
      expect((await store.configForRun(id))['tags'], ['x']);
    });
  });

  group('custom choices', () {
    test('adding selects the choice and keeps the note', () async {
      expect(
        await store.addCustomChoice(
          id,
          'model',
          '  my\u0000model ',
          subtitle: ' note ',
        ),
        ConfigWrite.written,
      );
      final data = await store.read(id);
      expect(data.values['model'], 'mymodel');
      expect(data.choices['model']!.single.value, 'mymodel');
      expect(data.choices['model']!.single.subtitle, 'note');
    });

    test('a name that is already an option is only selected', () async {
      await store.addCustomChoice(id, 'model', 'smart');
      final data = await store.read(id);
      expect(data.values['model'], 'smart');
      expect(data.choices, isEmpty);
      await store.addCustomChoice(id, 'model', 'mine');
      await store.addCustomChoice(id, 'model', 'mine');
      expect((await store.read(id)).choices['model'], hasLength(1));
    });

    test('limits: empty, 200 / 300 code points, 50 options', () async {
      expect(
        await store.addCustomChoice(id, 'model', '  '),
        ConfigWrite.invalidValue,
      );
      expect(
        await store.addCustomChoice(id, 'model', 'x' * 201),
        ConfigWrite.invalidValue,
      );
      expect(
        await store.addCustomChoice(id, 'model', 'x' * 200),
        ConfigWrite.written,
      );
      expect(
        await store.addCustomChoice(id, 'model', 'n', subtitle: 'y' * 301),
        ConfigWrite.invalidValue,
      );
      // 2 own options + 1 added = 3; fill up to 50 in total.
      for (var i = 0; i < 47; i++) {
        expect(
          await store.addCustomChoice(id, 'model', 'm$i'),
          ConfigWrite.written,
        );
      }
      expect(
        await store.addCustomChoice(id, 'model', 'one-more'),
        ConfigWrite.invalidValue,
      );
      expect((await store.read(id)).choices['model'], hasLength(48));
    });

    test('only a custom select takes choices', () async {
      expect(
        await store.addCustomChoice(id, 'mode', 'x'),
        ConfigWrite.unknownKey,
      );
      expect(
        await store.addCustomChoice(id, 'nope', 'x'),
        ConfigWrite.unknownKey,
      );
      expect(
        await store.removeCustomChoice(id, 'mode', 'x'),
        ConfigWrite.unknownKey,
      );
    });

    test('removing the selected choice selects the first option', () async {
      await store.addCustomChoice(id, 'model', 'mine');
      expect(
        await store.removeCustomChoice(id, 'model', 'mine'),
        ConfigWrite.written,
      );
      final data = await store.read(id);
      expect(data.values['model'], 'fast');
      expect(data.choices, isEmpty);
    });

    test('removing another choice keeps the selection', () async {
      await store.addCustomChoice(id, 'model', 'one');
      await store.addCustomChoice(id, 'model', 'two');
      await store.removeCustomChoice(id, 'model', 'one');
      final data = await store.read(id);
      expect(data.values['model'], 'two');
      expect(data.choices['model']!.map((c) => c.value), ['two']);
    });

    test(
      'a value that is not the user\'s own choice is invalidValue',
      () async {
        expect(
          await store.removeCustomChoice(id, 'model', 'fast'),
          ConfigWrite.invalidValue,
        );
        expect(
          await store.removeCustomChoice(id, 'model', 'ghost'),
          ConfigWrite.invalidValue,
        );
      },
    );

    test('removing with no option left clears the selection', () async {
      final fields = {
        'model': {'title': 'M', 'mode': 'select', 'custom': true},
      };
      await rows.switchPackage(
        id,
        draftOf(packageOf(manifestWith(fields)), 'v3-2'),
      );
      await store.addCustomChoice(id, 'model', 'only');
      await store.removeCustomChoice(id, 'model', 'only');
      expect((await store.read(id)).values, isEmpty);
    });
  });

  group('adaptToForm', () {
    Future<void> update(Map<String, Object?> fields) async {
      final before = rows.manifestOf((await rows.liveById(id))!)!.config;
      await rows.transaction(() async {
        final row = (await rows.switchPackage(
          id,
          draftOf(packageOf(manifestWith(fields)), 'v4-${now++}'),
        ))!.now;
        await store.adaptToForm(id, before, rows.manifestOf(row)!.config);
      });
    }

    test('keeps what still fits, drops the rest', () async {
      await store.setValue(id, 'token', 'k');
      await store.setValue(id, 'count', 9);
      await store.setValue(id, 'mode', 'b');
      await store.setValue(id, 'tags', ['x']);
      final fields = _fields();
      fields.remove('token');
      (fields['count']! as Map)['max'] = 5; // 9 no longer fits
      (fields['mode']! as Map)
        ..['format'] = 'multiple'
        ..remove('default'); // mode changed
      await update(fields);
      expect((await store.read(id)).values, {
        'tags': ['x'],
      });
    });

    test('a field that changed its input format loses the value', () async {
      await store.setValue(id, 'token', 'k');
      final fields = _fields();
      (fields['token']! as Map)['format'] = 'url';
      await update(fields);
      expect((await store.read(id)).values.containsKey('token'), isFalse);
    });

    test(
      'choices stay while the field is still custom, go otherwise',
      () async {
        await store.addCustomChoice(id, 'model', 'mine');
        await update(_fields());
        var data = await store.read(id);
        expect(data.values['model'], 'mine');
        expect(data.choices['model'], hasLength(1));

        final fields = _fields();
        (fields['model']! as Map).remove('custom');
        await update(fields);
        data = await store.read(id);
        expect(data.choices, isEmpty);
        expect(data.values.containsKey('model'), isFalse);
      },
    );

    test(
      'a removed or missing plugin is unknownKey and writes nothing',
      () async {
        await store.setValue(id, 'token', 'k');
        final before = rows.manifestOf((await rows.liveById(id))!)!.config;
        await rows.remove(id);
        expect(
          await store.adaptToForm(id, before, const []),
          ConfigWrite.unknownKey,
        );
        expect(
          await store.adaptToForm(testInstallId(8), before, const []),
          ConfigWrite.unknownKey,
        );
        expect(await db.select(db.pluginData).get(), isEmpty);
      },
    );

    test('an unchanged form writes nothing', () async {
      await store.setValue(id, 'token', 'k');
      var writes = 0;
      final sub = db
          .tableUpdates(TableUpdateQuery.onTable(db.pluginData))
          .listen((_) => writes++);
      await update(_fields());
      await pumpEventQueue();
      await sub.cancel();
      expect(writes, 0);
      expect((await store.read(id)).values, {'token': 'k'});
    });

    test(
      'rolls back with the package switch when the transaction fails',
      () async {
        await store.setValue(id, 'token', 'k');
        final before = rows.manifestOf((await rows.liveById(id))!)!.config;
        await expectLater(
          rows.transaction(() async {
            final row = (await rows.switchPackage(
              id,
              draftOf(packageOf(manifestWith({})), 'v4-9'),
            ))!.now;
            await store.adaptToForm(id, before, rows.manifestOf(row)!.config);
            throw StateError('boom');
          }),
          throwsStateError,
        );
        expect((await store.read(id)).values, {'token': 'k'});
        expect((await rows.liveById(id))!.packageDir, 'v3-1');
      },
    );
  });

  group('watch', () {
    test('emits on change only, per plugin', () async {
      final other = testInstallId(2);
      await rows.installOrRevive(
        other,
        draftOf(packageOf(manifestWith(_fields())), 'v3-5'),
        const PluginSource.file('b.zip'),
      );
      final seen = <Map<String, Object?>>[];
      final sub = store.watch(id).listen((d) => seen.add(d.values));
      await pumpEventQueue();
      await store.setValue(other, 'token', 'zzz');
      await store.setValue(id, 'token', 'a');
      await store.setValue(id, 'token', 'a');
      await pumpEventQueue();
      await store.setValue(id, 'token', 'b');
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [
        {},
        {'token': 'a'},
        {'token': 'b'},
      ]);
    });

    test('a removed plugin reads empty', () async {
      await store.setValue(id, 'token', 'a');
      await rows.remove(id);
      expect((await store.read(id)).values, isEmpty);
      expect(await store.watch(id).first, isA<PluginConfigData>());
    });
  });

  group('stored text', () {
    test('damaged text counts as nothing', () async {
      await db.customStatement(
        "UPDATE plugin_data SET config_json = '{oops', custom_choices_json = '[1,2]'",
      );
      final data = await store.read(id);
      expect(data.values, isEmpty);
      expect(data.choices, isEmpty);
      expect((await store.configForRun(id))['count'], 3);
    });

    test('malformed choices are dropped one by one', () {
      final choices = decodeChoices(
        '{"model":[{"value":"ok","subtitle":"n"},{"value":1},"x",{"value":""}],'
        '"bad":"x"}',
      );
      expect(choices.keys, ['model']);
      expect(choices['model']!.single.value, 'ok');
      expect(choices['model']!.single.subtitle, 'n');
    });
  });

  group('effective field', () {
    final field = SelectField(
      key: 'm',
      title: 'M',
      custom: true,
      options: const [ConfigOption(value: 'a', title: 'A')],
    );

    test('adds choices after the options, without repeats', () {
      final eff = effectiveField(field, [
        const CustomChoice('b', 'note'),
        const CustomChoice('a'),
        const CustomChoice('b'),
        const CustomChoice(''),
      ]) as SelectField;
      expect(eff.options.map((o) => o.value), ['a', 'b']);
      expect(eff.options.last.subtitle, 'note');
    });

    test('is capped at 50 options', () {
      final eff = effectiveField(field, [
        for (var i = 0; i < 80; i++) CustomChoice('c$i'),
      ]) as SelectField;
      expect(eff.options, hasLength(configMaxItems));
    });

    test('other fields and non-custom selects are returned as they are', () {
      const plain = SelectField(key: 'm', title: 'M');
      expect(
        identical(effectiveField(plain, [const CustomChoice('x')]), plain),
        isTrue,
      );
      const input = InputField(key: 'k', title: 'K');
      expect(
        identical(effectiveField(input, [const CustomChoice('x')]), input),
        isTrue,
      );
    });
  });
}
