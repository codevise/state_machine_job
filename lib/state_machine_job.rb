require 'state_machine_job/version'
require 'state_machine_job/macro'

module StateMachineJob
  def perform(record, payload = {})
    record_name = "#{record.class.name} #{record.id}"
    logger.info "perform for #{record_name}"

    begin
      result = perform_with_result(record, payload)
    rescue StandardError
      record.restore_attributes unless record.valid?
      result = :error
      raise
    ensure
      logger.info "result #{result} for #{record_name}"
      record.send(StateMachineJob.result_method_name(self.class, result))
    end
  end

  def self.result_event_name(job, result)
    [job.name.underscore.split('/'), result].flatten.join('_').to_sym
  end

  def self.result_method_name(job, result)
    "#{result_event_name(job, result)}!"
  end
end
