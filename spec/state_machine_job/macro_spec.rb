require 'spec_helper'

require 'rspec/rails/matchers/active_job'
require 'timecop'

module StateMachineJob
  describe Macro do
    class TestJob < ActiveJob::Base
      include StateMachineJob
    end

    class BaseModel
      include ActiveModel::Model
      include GlobalID::Identification

      attr_accessor :id

      cattr_accessor :instances

      def initialize(*)
        super
        instances[id] = self
      end

      def self.find(id)
        instances.fetch(id.to_i)
      end
    end

    before do
      BaseModel.instances = {}
    end

    class Model < BaseModel
      attr_accessor :state, :some_attribute

      state_machine initial: :idle do
        extend StateMachineJob::Macro

        state :idle
        state :running
        state :done
        state :failed

        event :run do
          transition idle: :running
        end

        job TestJob do
          on_enter :running
          payload do |record|
            {some_attribute: record.some_attribute}
          end
          result ok: :done
        end
      end
    end

    it 'enques job with record and payload arguments when entering on_enter state' do
      record = Model.new(id: 5, some_attribute: 'value')

      record.run

      expect(TestJob).to have_been_enqueued.with(record, some_attribute: 'value')
    end

    class ModelWithRetry < BaseModel
      attr_accessor :state, :some_attribute

      state_machine initial: :idle do
        extend StateMachineJob::Macro

        state :idle
        state :running
        state :done
        state :failed

        event :run do
          transition idle: :running
        end

        job TestJob do
          on_enter :running
          payload do |record|
            {some_attribute: record.some_attribute}
          end
          result ok: :done
          result :failed, retry_after: 60
        end
      end
    end

    it 'enques job after retry time with record and payload when result event is invoked' do
      Timecop.freeze do
        record = ModelWithRetry.new(id: 5, some_attribute: 'value')

        record.state_machine_job_test_job_failed!

        expect(TestJob).to have_been_enqueued
          .at(60.seconds.from_now).with(record, some_attribute: 'value')
      end
    end

    it 'has event for job result which transitions to result state' do
      object = Class.new do
        state_machine initial: :idle do
          extend StateMachineJob::Macro

          state :idle
          state :running
          state :done
          state :failed

          event :run do
            transition idle: :running
          end

          job TestJob do
            on_enter :running
            result ok: :done
          end
        end
      end.new

      object.state = :running
      object.state_machine_job_test_job_ok

      expect(object.state).to eq('done')
    end

    it 'result supports state option signature' do
      object = Class.new do
        state_machine initial: :idle do
          extend StateMachineJob::Macro

          state :idle
          state :running
          state :done

          event :run do
            transition idle: :running
          end

          job TestJob do
            on_enter :running
            result :ok, state: :done
          end
        end
      end.new

      object.state = :running
      object.state_machine_job_test_job_ok

      expect(object.state).to eq('done')
    end

    it 'result raises descriptive error when trying to use hash only signature with additional options' do
      expect {
        Class.new do
          state_machine initial: :idle do
            extend StateMachineJob::Macro

            job TestJob do
              on_enter :running
              result ok: :done, if: true
            end
          end
        end
      }.to raise_error(/Use an explicit :state option/)
    end

    describe ':if option' do
      it 'allows skipping matching results' do
        object = Class.new do
          state_machine initial: :idle do
            extend StateMachineJob::Macro

            state :idle
            state :running
            state :done
            state :other

            event :run do
              transition idle: :running
            end

            job TestJob do
              on_enter :running
              result :ok, state: :done, if: -> { false }
              result :ok, state: :other
            end
          end
        end.new

        object.state = :running
        object.state_machine_job_test_job_ok

        expect(object.state).to eq('other')
      end

      it 'uses matching results if condition is truthy' do
        object = Class.new do
          state_machine initial: :idle do
            extend StateMachineJob::Macro

            state :idle
            state :running
            state :done
            state :other

            event :run do
              transition idle: :running
            end

            job TestJob do
              on_enter :running
              result :ok, state: :done, if: -> { true }
              result :ok, state: :other
            end
          end
        end.new

        object.state = :running
        object.state_machine_job_test_job_ok

        expect(object.state).to eq('done')
      end

      it 'raises descriptive error when used in combination with :retry_after option' do
        expect {
          Class.new do
            state_machine initial: :idle do
              extend StateMachineJob::Macro

              job TestJob do
                on_enter :running
                result :ok, state: :done, if: true, retry_after: 100
              end
            end
          end
        }.to raise_error(/not supported/)
      end
    end

    describe ':retry_if_state option' do
      class ModelWithRetryIfState < BaseModel
        attr_accessor :state, :some_attribute

        state_machine initial: :idle do
          extend StateMachineJob::Macro

          state :idle
          state :running
          state :done
          state :failed

          event :run do
            transition idle: :running
            transition running: :rerun_required
          end

          job TestJob do
            on_enter :running
            result :ok, state: :done, retry_if_state: :rerun_required
          end
        end
      end

      it 'returns to on_enter state if state matches option when job finishes' do
        object = ModelWithRetryIfState.new(id: 43)

        object.state = :running
        object.run
        object.state_machine_job_test_job_ok

        expect(object.state).to eq('running')
      end

      it 'returns to result state if state does not match option when job finishes' do
        object = ModelWithRetryIfState.new(id: 43)

        object.state = :running
        object.state_machine_job_test_job_ok

        expect(object.state).to eq('done')
      end

      it 'raises descriptive error when on_enter is used after result' do
        expect {
          Class.new do
            state_machine initial: :idle do
              extend StateMachineJob::Macro

              job TestJob do
                result :ok, state: :done, retry_if_state: :rerun_required
                on_enter :running
              end
            end
          end
        }.to raise_error(/on_enter call must appear above any result/)
      end

      it 'raises descriptive error when used in combination with :retry_after option' do
        expect {
          Class.new do
            state_machine initial: :idle do
              extend StateMachineJob::Macro

              job TestJob do
                on_enter :running
                result :ok, state: :done, retry_if_state: :rerun_required, retry_after: 100
              end
            end
          end
        }.to raise_error(/not supported/)
      end
    end

    it 'does not raise exception if on_enter is used after result without :retry_if_state option' do
      expect {
        Class.new do
          state_machine initial: :idle do
            extend StateMachineJob::Macro

            job TestJob do
              result :ok, state: :done
              on_enter :running
            end
          end
        end
      }.not_to raise_error
    end
  end
end
