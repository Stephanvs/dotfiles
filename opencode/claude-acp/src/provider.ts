import { Effect, Schema, Stream } from 'effect';
import { LanguageModel, LLMEvent, ProtocolID } from '@opencode/ai';
import type { LLMRequest, ProviderPackage } from '@opencode/ai';
import { Endpoint, Protocol, Route } from '@opencode/ai/route';
import type { TransportDef } from '@opencode/ai/route';
import type { AdapterCommand } from './acp.js';
import { Invocation, failure } from './invocation.js';

export function model(modelID: string, settings: ProviderPackage.Settings) {
  if (typeof settings.brokerID !== 'string') throw new Error('Claude ACP requires its V2 plugin permission broker');
  const brokerID = settings.brokerID;
  const command = settings.adapterCommand;
  if (command !== undefined && (!Array.isArray(command) || command.length === 0 || !command.every((item) => typeof item === 'string'))) throw new Error('adapterCommand must be a nonempty string array');
  const transport: TransportDef<null, null, LLMEvent> = {
    id: 'claude-acp-stdio',
    prepare: () => Effect.succeed(null),
    execute: (_, request) => Effect.gen(function* () {
      const invocation = new Invocation(request, brokerID, command as AdapterCommand | undefined);
      yield* Effect.addFinalizer(() => Effect.promise(invocation.close));
      return { frames: Stream.fromAsyncIterable(invocation.events(), failure) };
    }),
  };
  const protocol = Protocol.make({
    id: ProtocolID.make('claude-acp'),
    body: { schema: Schema.Null, from: (_: LLMRequest) => Effect.succeed(null) },
    stream: {
      event: Schema.toType(LLMEvent),
      initial: () => undefined,
      step: (state: undefined, event: LLMEvent) => Effect.succeed([state, [event]] as const),
    },
  });
  const route = Route.make({ id: 'claude-acp', provider: 'claude-acp', protocol, endpoint: Endpoint.path('stdio://claude-acp'), transport });
  return LanguageModel.make({ id: modelID, provider: 'claude-acp', route });
}
