module StateMachineJob
  module Macro
    def job(job_class, queue = Resque, &block)
      Job.new(job_class, self, queue).instance_eval(&block)
    end

    class Job
      def initialize(job, state_machine, queue)
        @job = job
        @state_machine = state_machine
        @queue = queue
        @payload = lambda do |*args|
          {}
        end
      end

      def result(job_result, options = {})
        if job_result.is_a?(Hash)
          return result(job_result.first.first, :state => job_result.first.last)
        end

        if options[:state]
          @state_machine.event(job_result_event_name(job_result)) do
            transition any => options[:state]
          end
        elsif options[:retry_after]
          @state_machine.define_helper :instance, retry_job_method_name(job_result) do |machine, object|
            @queue.enqueue_in(options[:retry_after], @job, object.class.name, object.id, @payload.call(object))
          end
        end
      end

      def on_enter(state)
        job, state_machine, queue = @job, @state_machine, @queue

        @state_machine.after_transition @state_machine.any => state do |object|
          queue.enqueue(job, object.class.name, object.id, @payload.call(object))
        end
      end

      def payload(&block)
        @payload = block
      end

      private

      def retry_job_method_name(result)
        "#{job_result_event_name(result)}!"
      end

      def job_result_event_name(result)
        [@job.name.underscore.split('/'), result].flatten.join('_').to_sym
      end
    end
  end
end
