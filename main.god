require 'dotenv'
Dotenv.load

BIN_PATH = File.expand_path('../bin', __FILE__)
LOG_PATH = File.expand_path('../log', __FILE__)

%w(bot publisher).each do |script|
  God.watch do |w|
    w.name = script
    w.log = "#{LOG_PATH}/god.log"
    w.start = "ruby #{BIN_PATH}/#{script}.rb"
    w.keepalive
  end
end