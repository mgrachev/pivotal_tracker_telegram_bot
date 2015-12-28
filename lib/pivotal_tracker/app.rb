require 'sinatra/base'
require 'multi_json'

module PivotalTracker
  class App < Sinatra::Base
    post '/activity' do
      json = MultiJson.load(request.body.read, symbolize_keys: true)

      project_id        = json[:project][:id]
      project_name      = json[:project][:name]
      username          = json[:performed_by][:name]
      highlight         = json[:highlight].tr(':', '')
      primary_resource  = json[:primary_resources][0]
      story_type        = primary_resource[:story_type]
      story_name        = primary_resource[:name]
      url               = primary_resource[:url]
      who_did_it        = "[#{project_name}] #{username} #{highlight}"

      message = case json[:kind]
                when 'story_create_activity'
                  "#{who_did_it} new #{story_type} \"#{story_name}\". See: #{url}"
                when 'story_update_activity', 'story_delete_activity'
                  return if highlight == 'estimated'
                  "#{who_did_it} #{story_type} \"#{story_name}\". See: #{url}"
                when 'comment_create_activity'
                  "#{who_did_it} to the #{story_type} \"#{story_name}\". See: #{url}"
                when 'epic_create_activity'
                  "#{who_did_it} new #{primary_resource[:kind]} \"#{story_name}\". See: #{url}"
                else
                  PivotalTracker::Base.logger.info("App -- Undefined kind : #{json}")
                  return
                end

      if message != ''
        project_key = "#{project_id}_#{project_name.tr(' ', '_')}"
        PivotalTracker::Base.redis.publish("#{PivotalTracker::Base::NAME}/activity/#{project_key}", message)
      end

      204
    end
  end
end
