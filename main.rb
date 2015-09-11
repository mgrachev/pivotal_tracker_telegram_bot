require 'bundler/setup'
require 'dotenv'
require 'redis'
require 'logger'
require 'telegram/bot'

Dotenv.load
$redis = Redis.new(timeout: 0)

LOG_PATH = 'log'
APP_LOG_PATH = File.expand_path("../#{LOG_PATH}/app.log", __FILE__)
BOT_LOG_PATH = File.expand_path("../#{LOG_PATH}/bot.log", __FILE__)
PUBLISHER_LOG_PATH = File.expand_path("../#{LOG_PATH}/publisher.log", __FILE__)

$app_logger = Logger.new(APP_LOG_PATH, 'weekly')
$bot_logger = Logger.new(BOT_LOG_PATH, 'weekly')
$publisher_logger = Logger.new(PUBLISHER_LOG_PATH, 'weekly')

$telegram_bot = Telegram::Bot::Client.new(ENV['TOKEN'], logger: $bot_logger)