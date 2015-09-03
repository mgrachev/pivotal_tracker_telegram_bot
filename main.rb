require 'bundler/setup'
require 'dotenv'
require 'redis'

Dotenv.load
$redis = Redis.new(timeout: 0)