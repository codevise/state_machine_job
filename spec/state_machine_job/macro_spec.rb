require 'spec_helper'

module StateMachineJob
  describe Macro do
    class TestJob
    end

    it 'enques job with model name, record id and payload arguments when entering on_enter state' do
      queue = double('queue')
      model = Class.new do
        attr_accessor :some_attribute

        def initialize(some_attribute)
          self.some_attribute = some_attribute
          super()
        end

        def id
          43
        end

        state_machine :initial => :idle do
          extend StateMachineJob::Macro

          state :idle
          state :running
          state :done
          state :failed

          event :run do
            transition :idle => :running
          end

          job TestJob, queue do
            on_enter :running
            payload do |record|
              {:some_attribute => record.some_attribute}
            end
            result :ok => :done
          end
        end
      end
      record = model.new('value')

      def model.name
        'Model'
      end

      expect(queue).to receive(:enqueue).with(TestJob, 'Model', 43, {:some_attribute => 'value'})
      record.run
    end

    it 'enques job after retry time with model name, record id and payload arguments when retry after result event is invoked' do
      queue = double('queue')
      model = Class.new do
        attr_accessor :some_attribute

        def initialize(some_attribute)
          self.some_attribute = some_attribute
          super()
        end

        def id
          43
        end

        state_machine :initial => :idle do
          extend StateMachineJob::Macro

          state :idle
          state :running
          state :done
          state :failed

          job TestJob, queue do
            on_enter :running
            payload do |record|
              {:some_attribute => record.some_attribute}
            end
            result :failed, :retry_after => 60
            result :ok => :done
          end
        end
      end
      record = model.new('value')

      def model.name
        'Model'
      end

      expect(queue).to receive(:enqueue_in).with(60, TestJob, 'Model', 43, {:some_attribute => 'value'})
      record.state_machine_job_test_job_failed!
    end

    it 'has event for job result which transitions to result state' do
      object = Class.new do
        state_machine :initial => :idle  do
          extend StateMachineJob::Macro

          state :idle
          state :running
          state :done
          state :failed

          event :run do
            transition :idle => :running
          end

          job TestJob do
            on_enter :running
            result :ok => :done
          end
        end
      end.new

      object.state = :running
      object.state_machine_job_test_job_ok

      expect(object.state).to eq('done')
    end

    it 'result supports state option signature' do
      object = Class.new do
        state_machine :initial => :idle  do
          extend StateMachineJob::Macro

          state :idle
          state :running
          state :done

          event :run do
            transition :idle => :running
          end

          job TestJob do
            on_enter :running
            result :ok, :state => :done
          end
        end
      end.new

      object.state = :running
      object.state_machine_job_test_job_ok

      expect(object.state).to eq('done')
    end

    describe ':retry_if_state option' do
      it 'returns to on_enter state if state matches option when job finishes' do
        queue = double('queue')
        object = Class.new do
          def id
            43
          end

          state_machine :initial => :idle  do
            extend StateMachineJob::Macro

            state :idle
            state :running
            state :done
            state :failed

            event :run do
              transition :idle => :running
              transition :running => :rerun_required
            end

            job TestJob, queue do
              on_enter :running
              result :ok, :state => :done, :retry_if_state => :rerun_required
            end
          end
        end.new

        expect(queue).to receive(:enqueue).with(TestJob, nil, 43, {})

        object.state = :running
        object.run
        object.state_machine_job_test_job_ok

        expect(object.state).to eq('running')
      end

      it 'returns to result state if state does not match option when job finishes' do
        queue = double('queue')
        object = Class.new do
          def id
            43
          end

          state_machine :initial => :idle  do
            extend StateMachineJob::Macro

            state :idle
            state :running
            state :done
            state :failed

            event :run do
              transition :idle => :running
              transition :running => :rerun_required
            end

            job TestJob, queue do
              on_enter :running
              result :ok, :state => :done, :retry_if_state => :rerun_required
            end
          end
        end.new

        object.state = :running
        object.state_machine_job_test_job_ok

        expect(object.state).to eq('done')
      end

      it 'raises descriptive error when on_enter is used after result' do
        expect {
          Class.new do
            state_machine :initial => :idle  do
              extend StateMachineJob::Macro

              job TestJob do
                result :ok, :state => :done, :retry_if_state => :rerun_required
                on_enter :running
              end
            end
          end
        }.to raise_error(/on_enter call must appear above any result/)
      end

      it 'raises descriptive error when used in combination with :retry_after option' do
        expect {
          Class.new do
            state_machine :initial => :idle  do
              extend StateMachineJob::Macro

              job TestJob do
                on_enter :running
                result :ok, :state => :done, :retry_if_state => :rerun_required, :retry_after => 100
              end
            end
          end
        }.to raise_error(/not supported/)
      end
    end
  end
end
