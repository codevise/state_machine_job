# CHANGELOG

### Unreleased Changes

- Do not silence exceptions. Ensure state machine can transition to
  failed state by invoking error result event, but then re-raise
  exception, so they show up in the Resque error list. Jobs are still
  free to rescue exceptions themselves and return an error result
  instead.
  ([#5](https://github.com/codevise/state_machine_job/pull/5))
- Add backtrace info to exception logging
  ([#3](https://github.com/codevise/state_machine_job/pull/3))
- Restrict activesupport to < 5 for now
  ([#4](https://github.com/codevise/state_machine_job/pull/4))
- Use sinatra 1 in development and tests for ruby 2.1 compatibility
  ([#6](https://github.com/codevise/state_machine_job/pull/6))

See
[0-2-stable branch](https://github.com/codevise/state_machine_job/blob/0-2-stable/CHANGELOG.md)
for previous changes.
