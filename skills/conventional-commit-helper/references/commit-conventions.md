# Conventional Commit Conventions

## Template

```text
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

## Subject Rules

- imperative / present tense (`add`, `fix`, `update`, `remove`)
- lowercase
- no trailing period
- recommended length: <= 50 characters

## Scope Naming

Use module/layer/folder names whenever possible:

- `api`: controller / route / handler
- `auth`: login / token / permission
- `db`: schema / migration / repository
- `service`: domain use cases
- `config`: environment / flags
- `deps`: dependency updates
- `ci`: CI pipeline/config
- `docs`: documentation
- `test`: tests

## Type to SemVer Impact

- `feat`: minor
- `fix`, `perf`, `revert`: patch
- `docs`, `style`, `refactor`, `test`, `build`, `ci`, `chore`: no release bump

## Body Guidance

Use bullets for fast review.

Example:

```text
fix(db): prevent deadlock on order update

- use indexed column in where clause
- reduce transaction scope to single statement
- add retry on lock wait timeout
```

## Footer Guidance

Issue references:

```text
refs: #123
closes: #456
```

Breaking changes:

```text
feat(auth)!: remove legacy session cookie
```

or:

```text
feat(auth): remove legacy session cookie

BREAKING CHANGE: clients must send bearer token instead of session cookie
```
