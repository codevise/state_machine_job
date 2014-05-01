require 'resque_logger'

log_dir = 'spec/tmp/log'
FileUtils.mkdir_p(log_dir)

Resque.logger_config = {
  folder: log_dir,
  class_name: Logger,
  level:      Logger::INFO,
  formatter:  Logger::Formatter.new
}
