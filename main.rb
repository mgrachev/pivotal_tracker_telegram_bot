require 'bundler/setup'
require 'dotenv'
require 'redis'
require 'logger'

Dotenv.load
$redis = Redis.new(timeout: 0)

LOG_PATH = 'log'
BOT_LOG_PATH = File.expand_path("#{LOG_PATH}/bot.log", __FILE__)
PUBLISHER_LOG_PATH = File.expand_path("#{LOG_PATH}/publisher.log", __FILE__)

$bot_logger = Logger.new(BOT_LOG_PATH, 'weekly')
$publisher_logger = Logger.new(PUBLISHER_LOG_PATH, 'weekly')