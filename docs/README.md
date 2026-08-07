# docs/ — running several agents as one team

Six chapters, in the order the problems actually arrive.

The first agent is a tool. The second one turns it into an organisation, and an organisation needs
three things a single agent never did: a written statement of who each member is and what they may
do, an agreed way for work to travel between them, and a way to answer "who covers this?" without
asking every member to self-report.

| Chapter | Read it when | State |
|---|---|---|
| `fleet-charter.md` | before the second agent exists — what a charter declares, what it must never contain, and how it gets enforced at runtime instead of admired in a file. Fill in `../AGENTS.md` as you read it | **written** |
| `adding-an-agent.md` | every time you add one — the onboarding path end to end, the settings that silently default wrong, and the drills that prove the new member is real | **written** |
| `agent-dispatch.md` | the day a request arrives while an agent is busy — queueing instead of dropping, who may trigger write scope, and why an answer must be matched to its request by id and never by time | **written** |
| `skill-registry.md` | when nobody can say which agent or skill covers which job — a registry that outranks self-claims, and the guard that keeps it from going stale | planned |
| `working-agreement.md` | when two agents disagree, or one starts deciding things that were not its to decide — decision tiers, briefs, and what a hand-off must carry | planned |
| `fleet-health.md` | once the fleet runs unattended — enumerate members from the system rather than a list you maintain, and alarms that prove delivery instead of assuming silence means healthy | planned |

## Why prose and not a framework

Everything portable here is a **contract**. The code that enforces it is short and belongs to your
runtime; the contract is the part that takes months to learn, because every one of these failures
looks like success from the outside: work accepted and never run, an answer to somebody else's
question, an agent that has been "busy" for fourteen minutes with nothing running, a registry that
lists a skill nobody has been able to load since April.

The one runnable piece is `../scripts/dispatch-client.sh`, because the sender side of dispatch is
where the most expensive silent failures live and prose converts to a correct client poorly.

## Suggested order

1. `fleet-charter.md` — write one before you need it. Retrofitting a charter onto three agents that
   already have habits is a much worse afternoon.
2. `adding-an-agent.md` — use it as a checklist the first time, then keep it as the retirement path.
3. `agent-dispatch.md` — the day the second sender appears, whether that is a second person or a
   scheduled job.
4. The rest when the matching symptom shows up. They are written to be read cold, in any order.
