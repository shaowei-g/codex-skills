# Review Checklist

Use this checklist when reviewing a spec feature for alignment.

## Artifact Alignment

- [ ] `spec.md` states the problem, intended outcome, and scope boundaries
- [ ] `spec.md` acceptance criteria are explicit and testable
- [ ] `plan.md` stays within the scope defined by `spec.md`
- [ ] `tasks.md` covers the planned work without adding extra scope

## Implementation Alignment

- [ ] changed code maps to current tasks
- [ ] changed code maps to current acceptance criteria
- [ ] task state reflects reality
- [ ] no material implementation exists without matching artifact updates

## Evidence

- [ ] verification evidence exists for the implemented batch
- [ ] failed checks are documented
- [ ] untested areas are documented
- [ ] the next valid phase is stated explicitly

## Finding Types

Classify each finding as one of:

- blocker
- drift
- stale artifact
- verified
