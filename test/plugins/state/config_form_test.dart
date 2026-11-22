import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/state/config_form_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_page_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../data/store_test_support.dart';
import '../domain/plugin_test_support.dart';
import 'state_test_support.dart';

const _url = 'https://repo.example.com/plugins.json';

/// A form of every kind that matters to the form's state.
final _config = {
  'token': {
    'title': 'Token',
    'mode': 'input',
    'format': 'text',
    'required': true,
  },
  'host': {
    'title': 'Host',
    'mode': 'input',
    'format': 'text',
    'default': 'api.example.com',
  },
  'model': {
    'title': 'Model',
    'mode': 'select',
    'custom': true,
    'required': true,
    'options': <Object>[],
  },
};

void main() {
  late StateHarness h;
  late String id;
  setUp(() async {
    h = StateHarness();
    id = repoInstallId(_url, 'a');
    await h.container
        .read(pluginRowsProvider)
        .installOrRevive(
          id,
          draftOf(packageOf(withConfig(_config)), 'v3-1'),
          const PluginSource.repo(_url, 'a'),
        );
  });
  tearDown(() => h.dispose());

  ConfigOps ops() => h.container.read(configOpsProvider);

  Future<ConfigFormData> form() async =>
      (await h.settled(configFormProvider(id))).requireValue!;

  Future<List<String>> missing() async =>
      (await h.settled(pluginPageProvider(id))).requireValue!.missingConfig;

  test(
    'the form lists the fields in manifest order with their defaults',
    () async {
      final data = await form();
      expect(data.fields.map((f) => f.key), ['token', 'host', 'model']);
      expect(data.valueOf(data.field('host')!), 'api.example.com');
      expect(data.valueOf(data.field('token')!), isNull);
      expect(data.values, isEmpty);
    },
  );

  test(
    'a saved value shows in the form and takes the required band away at once',
    () async {
      expect(await missing(), ['Token', 'Model']);
      expect(await ops().setValue(id, 'token', 'abc'), ConfigWrite.written);
      expect((await form()).values['token'], 'abc');
      expect(await missing(), ['Model']);
      // Clearing a required value brings the band back.
      expect(await ops().setValue(id, 'token', null), ConfigWrite.written);
      expect((await form()).values.containsKey('token'), isFalse);
      expect(await missing(), ['Token', 'Model']);
    },
  );

  test('a custom choice joins the field, is the user\'s own and fills the requirement', () async {
    expect(
      await ops().addChoice(id, 'model', 'llama3', note: 'Ollama'),
      ConfigWrite.written,
    );
    final data = await form();
    final model = data.field('model')! as SelectField;
    expect(model.options.map((o) => o.value), ['llama3']);
    expect(model.options.single.subtitle, 'Ollama');
    expect(data.isOwn('model', 'llama3'), isTrue);
    expect(data.valueOf(model), 'llama3');
    expect(await missing(), ['Token']);

    // Removing the only choice leaves nothing chosen and the band says so.
    expect(
      await ops().removeChoice(id, 'model', 'llama3'),
      ConfigWrite.written,
    );
    final after = await form();
    expect((after.field('model')! as SelectField).options, isEmpty);
    expect(after.valueOf(after.field('model')!), isNull);
    expect(await missing(), ['Token', 'Model']);
  });

  test('the store refuses what does not fit, and says what', () async {
    expect(await ops().setValue(id, 'nope', 'x'), ConfigWrite.unknownKey);
    expect(
      await ops().setValue(id, 'model', 'not-a-choice'),
      ConfigWrite.invalidValue,
    );
    expect(await ops().addChoice(id, 'token', 'x'), ConfigWrite.unknownKey);
    expect(
      await ops().removeChoice(id, 'model', 'never-added'),
      ConfigWrite.invalidValue,
    );
    expect(
      await ops().setValue(id, 'token', 'x' * 3000),
      ConfigWrite.invalidValue,
    );
  });

  test(
    'a plugin that is gone has no form and its writes find no field',
    () async {
      await h.container.read(pluginRowsProvider).remove(id);
      expect(await ops().setValue(id, 'token', 'x'), ConfigWrite.unknownKey);
      final status = await h.settled(configFormProvider(id));
      expect(status.value, isNull);
    },
  );
}
