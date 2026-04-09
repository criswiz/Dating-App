# Test Strategy

## Quality Gates

- Backend lint and tests must pass in CI.
- Mobile analyzer and tests must pass in CI.
- Contract checks for critical JSON payload shapes should be covered in API tests.
- Merge is blocked if required checks fail.

## Backend Pyramid

- Unit tests:
  - match scoring logic
  - safety and moderation service rules
  - token/auth utility functions
- API integration tests:
  - auth signup/login
  - discovery feed ranking and filtering
  - likes/passes/matches/chat flow
  - report/block/rate-limit behavior
- Performance tests:
  - smoke load tests against discovery and auth endpoints

## Mobile and Web (Flutter)

- Unit tests:
  - provider/service state transitions
  - JSON mapping and API fallback behavior
- Widget tests:
  - login/signup form flows
  - discover interaction controls
- Integration tests:
  - happy path from auth to first interaction

## Done Definition

Every merged feature should include:

- acceptance criteria reference
- at least one automated test (unit, widget, or integration)
- rollback note in PR description
