require 'action_controller/railtie'
require 'rspec/rails'

PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..')).freeze
$LOAD_PATH << File.join(PROJECT_ROOT, 'lib')

require 'active_support/inflector'
require 'active_model'
require 'active_job'
require 'state_machines-activemodel'
require 'state_machine_job'

ActiveJob::Base.logger = Logger.new(nil)
ActiveJob::Base.queue_adapter = :test

GlobalID.app = :test
