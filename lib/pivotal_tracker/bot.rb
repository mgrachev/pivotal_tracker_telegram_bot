require_relative '../pivotal_tracker'

module PivotalTracker
  class Bot < Base
    BOT_NAME = 'Pivotal Tracker Bot'.freeze
    HELP = <<HELP
Initially, the need to integrate the bot with Pivotal Tracker.
See: https://github.com/mgrachev/pivotal_tracker_telegram_bot

Available commands:
/start - Start a #{BOT_NAME}
/track - Tracking project
/stop  - Stop tracking project
/help  - Show hint

Support: #{ENV['SUPPORT_EMAIL']}
HELP

    TRACK_ARGUMENT_ERROR = "You must specify the Project ID and Name.\nExample: /track 1234567 My Sample Project".freeze
    TRACK_ONE_PROJECT_IN_FEW_CHATS = "The project is already being tracked in another chat.\nTo track the project in this chat, you must first stop tracking in the other chat."
    STOP_ARGUMENT_ERROR = "You must specify the Project Name.\nExample: /stop My Sample Project".freeze

    class << self
      attr_reader :chat_id, :project_key, :project_name, :args
    end

    def self.run
      telegram_bot.run do |bot|
        bot.listen do |message|
          @chat_id = message.chat.id

          case message.text
          when %r{^\/start}
            bot.api.sendMessage(chat_id: chat_id, text: "Hello! I #{BOT_NAME} and I'm ready to track your projects. Enter /track")
          when %r{^\/help}
            bot.api.sendMessage(chat_id: chat_id, text: HELP, disable_web_page_preview: true)
          when %r{^\/track}
            @args = message.text.split(' ')

            if args.length < 3
              bot.api.sendMessage(chat_id: chat_id, text: TRACK_ARGUMENT_ERROR)
              next
            end

            project_id    = args[1]
            @project_name = args[2..-1].join('_')
            @project_key  = "#{project_id}_#{project_name}"
            chat_key      = "#{NAME}/chat_id/#{project_key}"

            if redis.exists(chat_key)
              bot.api.sendMessage(chat_id: chat_id, text: TRACK_ONE_PROJECT_IN_FEW_CHATS)
              next
            end

            redis.set(chat_key, chat_id)
            # To stop tracking project
            redis.sadd("#{NAME}/project_key/#{chat_id}", project_key)

            bot.api.sendMessage(chat_id: chat_id, text: "Start tracking project \"#{project_name.tr('_', ' ')}\"")
          when %r{^\/stop}
            @args = message.text.split(' ')
            if args.length < 2
              bot.api.sendMessage(chat_id: chat_id, text: STOP_ARGUMENT_ERROR)
              next
            end

            redis_project_key = "#{NAME}/project_key/#{chat_id}"

            unless redis.exists(redis_project_key)
              bot.api.sendMessage(chat_id: chat_id, text: 'No track projects')
              next
            end

            @project_name = args[1..-1].join('_')

            result = redis.sscan(redis_project_key, 0, match: "*#{project_name}")[1]

            if result.empty?
              bot.api.sendMessage(chat_id: chat_id, text: "Not found project \"#{project_name.tr('_', ' ')}\"")
              next
            end

            @project_key = result[0]
            redis_chat_key = "#{NAME}/chat_id/#{project_key}"

            redis.del(redis_chat_key)
            redis.srem(redis_project_key, project_key)

            projects = redis.smembers(redis_project_key)
            redis.del(redis_project_key) if projects.empty?

            bot.api.sendMessage(chat_id: chat_id, text: "Stop tracking project \"#{project_name.tr('_', ' ')}\"")
          end
        end
      end
    rescue => e
      send_to_errbit(e, method: __callee__, command: Regexp.last_match, **airbrake_params)
      retry
    end

    private

    def self.airbrake_params
      {
        project_key:  project_key,
        project_name: project_name,
        chat_id:      chat_id,
        args:         args
      }
    end
  end
end
