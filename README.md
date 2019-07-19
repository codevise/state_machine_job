# State Machine Job

[![Gem Version](https://badge.fury.io/rb/state_machine_job.svg)](http://badge.fury.io/rb/state_machine_job)
[![Build Status](https://travis-ci.org/codevise/state_machine_job.svg?branch=master)](https://travis-ci.org/codevise/state_machine_job)

Enqueue jobs on state machine transitions and change state according
to job result.

## Installation

Add this line to your application's Gemfile:

    gem 'state_machine_job'

## Usage

Include the `StateMachineJob` mixin in your job and provide a
`perform_with_result` method instead of the normal `perform` method:

    class SomeJob < ApplicationJob
      include StateMachineJob

      def perform_with_result(record, payload)
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
many results as you want.

Note that any exception raised by `perform_with_result` leads to a
state machine transition as if the result had been `:error`. The
exception is not rescued, though. If `perform_with_result` raises an
exception and the record is invalid, previous attribute values will be
restored before invoking the transition. That way the transition to
the error state can be persisted by rolling back the changes that led
to the records invalidity during job execution.

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

### Changing to States with Conditions

One job result can lead to different states based on a conditional.
When the job finishes with the given result, the state machine
transitions to the first state whose conditional evaluates to true.

    job SomeJob do
      on_enter 'running'

      result :ok, :state => 'special', :if => lambda { |record| record.some_condition? }
      result :ok, :state => 'other', :if => :other_condition?
      result :ok, :state => 'done'

      result :error => 'failed'
    end

A conditional can either be a lambda optionally accepting the
record as parameter or a symbol specifying a method to call on the
record.

### Retrying Jobs after a Delay

You can tell the state machine to retry a job based on its result:

    job SomeJob do
      on_enter 'running'

      result :ok => 'done'
      result :pending, :retry_after => 2.minutes
      result :error => 'failed'
    end

When `perform_with_result` returns the result `:pending`, the state
machine will remain in the `runnning` state and enqueue a delayed
job. This feature uses the Active Job `set(wait: n)` functionality.

### Retrying Jobs Based on State

You can tell the state machine to retry a job if a transition to a
certain state occures while a job is running:

    event :run do
      transition 'idle' => 'running'
      transition 'running' => 'rerun_requested'
    end

    job SomeJob do
      on_enter 'running'

      result :ok, :state => 'done', :retry_if_state => 'rerun_requested'
      result :error => 'failed'
    end

If the `run` event is invoked while the job is already running, you
can transition to a state signaling that the job will need to run
again once it has finished.  In example, passing the `:retry_if_state`
option causes the state machine to transition back to the `running`
state once the job finishes with result `:ok`.

## See also

[CHANGELOG](https://github.com/codevise/state_machine_job/blob/master/CHANGELOG.md)
