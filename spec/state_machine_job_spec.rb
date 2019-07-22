require 'spec_helper'

describe StateMachineJob do
  class TestJob < ActiveJob::Base
    include StateMachineJob

    def perform_with_result(record, payload); end
  end

  class Model
    include ActiveModel::Dirty
    include ActiveModel::Validations

    def id
      3
    end

    def test_job_ok!; end

    def test_job_error!; end
  end

  class ModelRequiringName < Model
    attr_reader :name

    validates_presence_of :name
    define_attribute_methods :name

    def initialize(name: nil)
      @name = name
      changes_applied
    end

    def name=(value)
      name_will_change! unless value == @name
      @name = value
    end
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

  it 'restores attributes of invalid record before invoking job result event ' \
     'if perform_with_result raises to ensure state transition can be persisted' do
    record = ModelRequiringName.new(name: 'Susan')
    job = TestJob.new

    record.name = ''
    allow(job).to receive(:perform_with_result).and_raise(SomeError)

    begin
      job.perform(record)
    rescue SomeError # rubocop:disable Lint/HandleExceptions
    ensure
      expect(record).to be_valid
    end
  end
end
