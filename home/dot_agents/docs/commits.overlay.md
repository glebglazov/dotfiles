Match the prefix the repo's recent commits use. Where that is a bracketed ticket key — `[SC-1234] <subject>`, `[GS-1234] <subject>` — use `[DEV]` when the key is not evident, and let the key be the whole prefix: after it, plain prose — `[SC-1234] Retry failed webhook deliveries`. Where the repo's convention is something else, follow that convention instead, including its type markers.

Write the subject as one sentence naming the intent of the change from the user's perspective. Commas are the only punctuation it needs. Leave implementation detail out unless the ticket's work is itself deeply technical.

Refer to a decision by its title or its substance — "switch sessions to signed cookies" — so the message reads whole without the ADR to hand. Keep ADR numbers out of the subject and the body.
