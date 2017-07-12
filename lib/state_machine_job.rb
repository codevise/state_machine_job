require 'state_machine_job/version'
require 'state_machine_job/macro'

require 'resque'
require 'resque/plugins/logger'
require 'resque_logger'

module StateMachineJob
  include Resque::Plugins::Logger

  def perform(model_name, id, payload = {})
    logger.info "#{self.name} - perform for #{model_name} #{id}"

    record = model_name.constantize.find_by_id(id)

    if record
      begin
        result = perform_with_result(record, payload)
      rescue Exception => e
        result = :error

        logger.error "#{self.name} - exception for #{model_name} #{id}: #{e.inspect}"
        e.backtrace.each { |line| logger.info(line) }

        raise
      ensure
        logger.info "#{self.name} - result #{result} for #{model_name} #{id}"
        record.send(event_name(result))
      end
    else
      logger.info "#{self.name} - #{model_name} #{id} not found. Skipping job."
    end
  end

  private

  def event_name(result)
    ([self.name.underscore.split('/'), result].flatten.join('_') + '!').to_sym
  end
end
