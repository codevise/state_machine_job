require 'spec_helper'

describe StateMachineJob do
  class TestQueue
    def enqueue(job, *args)
      job.perform(*args)
    end

    def self.instance
      @instance ||= TestQueue.new
    end
  end

  class TestJob1
    @queue = 'test_job_1'
    extend StateMachineJob
  end

  class TestJob2
    @queue = 'test_job_2'
    extend StateMachineJob
  end

  class Model
    state_machine :initial => :idle do
      extend StateMachineJob::Macro

      state :idle
      state :first_running
      state :second_running
      state :done

      event :run do
        transition :idle => :first_running
      end

      job TestJob1, TestQueue.instance do
        on_enter :first_running
        payload do |object|
          {:n => 1}
        end
        result :ok => :second_running
      end

      job TestJob2, TestQueue.instance do
        on_enter :second_running
        payload do |object|
          {:n => 2}
        end
        result :ok => :done
      end
    end
  end

  it 'calls find on model and passes record and payload to perform_with_result method' do
    model = Model.new

    allow(model).to receive(:id).and_return(5)
    allow(Model).to receive(:find_by_id).and_return(model)
    expect(TestJob1).to receive(:perform_with_result).with(model, {:n => 1}).and_return(:ok)
    expect(TestJob2).to receive(:perform_with_result).with(model, {:n => 2}).and_return(:ok)

    model.run
  end

  it 'invokes job result event on record' do
    model = Model.new

    allow(model).to receive(:id).and_return(5)
    allow(Model).to receive(:find_by_id).and_return(model)
    allow(TestJob1).to receive(:perform_with_result).and_return(:ok)
    allow(TestJob2).to receive(:perform_with_result).and_return(:ok)

    expect(model).to receive(:test_job1_ok!)

    model.run
  end

  it 'job is skipped if record cannot be found' do
    allow(Model).to receive(:find_by_id).and_return(nil)

    expect {
      TestJob1.perform(Model.name, -1, {})
    }.not_to raise_exception
  end
end
