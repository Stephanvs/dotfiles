import { Model, Plugin, Provider } from '@opencode/plugin/effect';
import { Effect } from 'effect';
import { discoverModels } from './acp.js';
import { registerBroker } from './broker.js';

const conservativeAdapterBudget = { context: 100_000, output: 8_000 };

export default Plugin.define({
  id: 'claude-acp',
  effect: (ctx) => Effect.gen(function* () {
    const models = yield* Effect.promise((signal) => discoverModels(ctx.location.directory, signal));
    const broker = registerBroker({ session: { get: ctx.session.get }, permission: { assert: ctx.permission.assert } });
    yield* Effect.addFinalizer(() => Effect.sync(broker.dispose));
    const providerID = Provider.ID.make('claude-acp');
    yield* ctx.provider.transform((editor) => editor.add({
      info: {
        ...Provider.Info.empty(providerID),
        name: 'Claude (ACP)', activation: 'enabled',
        package: new URL('./provider.js', import.meta.url).href,
        settings: { brokerID: broker.id },
      },
      models: models.map(({ id, name }) => ({
        ...Model.Info.default(providerID, Model.ID.make(id)), name,
        capabilities: { tools: true, input: ['text'], output: ['text'] },
        limit: conservativeAdapterBudget,
      })),
    }));
    yield* ctx.session.hook('model.request', (event) => Effect.sync(() => {
      event.headers['x-claude-acp-broker'] = broker.id;
      event.headers['x-claude-acp-session'] = event.sessionID;
      event.headers['x-claude-acp-kind'] = event.kind;
    }), { providerID: 'claude-acp' });
    yield* ctx.session.hook('retry', (event) => Effect.sync(() => { event.decision = { retry: false }; }), { providerID: 'claude-acp' });
  }),
});
