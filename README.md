# State Machine Job

[![Gem Version](https://badge.fury.io/rb/state_machine_job.svg)](http://badge.fury.io/rb/state_machine_job)
[![Build Status](https://travis-ci.org/codevise/state_machine_job.svg?branch=master)](https://travis-ci.org/codevise/state_machine_job)

Enqueue resque jobs on state machine transitions and change state
according to job result.

## Installation

Add this line to your application's Gemfile:

    gem 'state_machine_job'

Requires the [resque-logger](https://github.com/salizzar/resque-logger) 
gem to be present and configured.

## Usage

Extend your resque job with the `StateMachineJob` mixin and provide a
`perform_with_result` class method instead of the normal `perform`
method:

    class SomeJob
      extend StateMachineJob

      def self.perform_with_result(record, payload)
        # do something
        :ok
      end
    end

The `record` parameter is a reference to the object the state machine
will be defined on.

Now you can wire up the job in a state machine using the
`StateMachineJob::Macro`:

    state_machine :initial => 'idle' do
      extend StateMachineJob::Macro

      state 'idle'
      state 'running'
      state 'done'
      state 'failed'

      event :run do
        transition 'idle' => "running"
      end

      job SomeJob do
        on_enter 'running'

        result :ok => 'done'
        result :error => 'failed'
      end
    end

When the `state` attribute changes to `'running'` (either by the `run`
event or by manually updateing the attribute), `SomeJob` will
automatically be enqueued. If `perform_with_result` returns `:ok`, the
state machine transitions to the `'done'` state. You can specify as
many results as you want. Note that any exception raised by
`perform_with_result` is rescued and translated to the result
`:error`.

### Passing custom Payload

You can specify further options to pass to the `perform_with_result`
method using the `payload` method:

    job SomeJob do
      on_enter 'running'

      payload do |record|
        {:some_attribute => record.some_attribute}
      end

      result :ok => 'done'
      result :error => 'failed'
    end

`perform_with_result` is now called with the given hash of options as
the second parameter.

### Retrying Jobs

You can tell the state machine to retry a job based on its result:

    job SomeJob do
      on_enter 'running'

      result :ok => 'done'
      result :pending, :retry_after => 2.minutes
      result :error => 'failed'
    end

When `perform_with_result` returns the result `:pending`, the state
machine will remain in the `runnning` state and enqueue a delayed
job. This functionality requires the [`resque-scheduler`](https://github.com/resque/resque-scheduler) 
gem.
