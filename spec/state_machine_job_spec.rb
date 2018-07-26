require 'spec_helper'

describe StateMachineJob do
  class TestJob < ActiveJob::Base
    include StateMachineJob

    def perform_with_result(record, payload); end
  end

  class Model
    def id
      3
    end

    def test_job_ok!; end

    def test_job_error!; end
  end

  class SomeError < StandardError; end

  it 'passes record and payload to perform_with_result method' do
    record = Model.new
    payload = {n: 1}
    job = TestJob.new

    expect(job).to receive(:perform_with_result)
      .with(record, payload).and_return(:ok)

    job.perform(record, payload)
  end

  it 'invokes job result event on record' do
    record = Model.new
    job = TestJob.new

    allow(job).to receive(:perform_with_result).and_return(:ok)
    expect(record).to receive(:test_job_ok!)

    job.perform(record)
  end

  it 'lets exception bubble raised by perform_with_result' do
    record = Model.new
    job = TestJob.new

    allow(job).to receive(:perform_with_result).and_raise(SomeError)

    expect { job.perform(record) }.to raise_error(SomeError)
  end

  it 'invokes error job result event on record if perform_with_result raises' do
    record = Model.new
    job = TestJob.new

    allow(job).to receive(:perform_with_result).and_raise(SomeError)
    expect(record).to receive(:test_job_error!)

    begin
      job.perform(record)
    rescue SomeError # rubocop:disable Lint/HandleExceptions
    end
  end
end
