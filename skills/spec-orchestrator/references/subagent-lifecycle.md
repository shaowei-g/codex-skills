# Subagent Lifecycle Contract

This reference defines the required operating sequence for every specialist subagent delegated by `spec-orchestrator`.

## Lifecycle

Every delegated run must follow this sequence:

1. **Create**
   - instantiate one subagent for one named feature and one named bounded scope
   - bind the run to one assigned phase and one assigned subagent

2. **Inject**
   - begin with the direct identity-and-contract opening
   - use the standard sentence pattern:
     - `You are subagent <subagent-name>. Execute exactly one bounded unit of work for a single scope, return only the approved schema response, then stop.`
   - immediately provide a compact `Load and follow:` list
   - reference shared contracts by path instead of pasting them inline whenever possible

3. **Load Context**
   - load prompt guidance using `./codex-prompt-mapping.md`
   - read only the feature artifacts and code needed for the assigned scope
   - prefer durable workflow artifacts over chat history

4. **Validate Entry Gate**
   - check the assigned specialist skill for entry expectations
   - if the gate fails, stop without doing adjacent-phase work
   - return `blocked` or `rejected` using the shared schema

5. **Execute Single Scope**
   - perform only the assigned bounded unit of work
   - do not expand into another batch, another feature, or another phase
   - record blockers or drift instead of absorbing extra work

6. **Persist Durable Outputs**
   - update only the files owned by the assigned scope
   - if no safe write is possible, explain why in the return payload

7. **Return Fixed Response**
   - return only the schema defined in `./subagent-response-format.md`
   - include scope, files read, files changed, blockers, evidence, and advisory next-step fields

8. **Stop**
   - stop immediately after returning the result
   - do not self-continue, reroute, or invoke another phase

9. **Clear**
   - close subagent after validation of the returned result is passed

## Delegation Expectations

The orchestrator should make all of the following explicit:

- target feature
- artifact directory path
- assigned scope
- assigned phase
- assigned subagent
- specialist skill reference
- repository prompt reference
- required response schema reference
- validator reference
- allowed write set
- forbidden write set
- stop-after-completion instruction

## Related References

- prompt lookup: `./codex-prompt-mapping.md`
- delegation contract: `./subagent-reinjection-contract.md`
- fallback and classification: `./subagent-prompt-fallbacks.md`
- response schema: `./subagent-response-format.md`
