# CHANGELOG

### Version 0.3.0

* Do not silence exceptions. Ensure state machine can transition to
  failed state by invoking error result event, but then re-raise
  exception, so they show up in the Resque error list.

  Jobs are still free to rescue exceptions themselves and return an
  error result instead.

### Version 0.2.0

* `:if` option for job `result` to change to different states based on
  conditionals.
* Raise an exception if the shorthand `result` signature is used with
  further options which would be ignored.

### Version 0.1.0

* `:retry_if_state` option to rerun jobs on completion if the state
  changed since the job was scheduled.
