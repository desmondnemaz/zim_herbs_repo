---
trigger: always_on
---

Project engineering rules

Inspect the existing project structure and explain the proposed changes before editing files.

Do not rewrite unrelated files or change the architecture without justification.

Preserve existing business rules, database relationships, API contracts, and user-facing behaviour.

Identify genuinely unused code before removing it; explain how you verified that it is unused.

Never change database schemas, migrations, row-level security policies, authentication, or authorization rules without explaining the implications and requesting approval.

Make changes in small, reviewable steps.

Run relevant tests, static analysis, and formatting checks where available.

Report every modified file, the reason for each change, tests performed, and any remaining risks.

Do not claim that tests passed unless they were actually executed and their results checked.

Prefer readable, maintainable code over unnecessary abstractions or merely reducing line count.

Learning requirement: For every significant change, explain the underlying programming concept and how the modified components interact.