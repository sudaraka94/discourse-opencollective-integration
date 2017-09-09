# name: opencollective-plugin
# about: This is intended to be a feature-rich plugin for opencollective-discourse integration
# version: 0.1
# authors: Sudaraka Jayathilaka
# url: https://github.com/sudaraka94/opencollective-plugin.git


require 'net/http'
require 'uri'
require 'json'

module ::OpencollectivePlugin
  BADGE_NAME ||= 'OpenCollective Donator'.freeze

  def self.get_data!
    token='eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzY29wZSI6ImxvZ2luIiwiaWQiOjM5MzksImVtYWlsIjoiYXBpK3Rlc3R1c2VyQG9wZW5jb2xsZWN0aXZlLmNvbSIsImlhdCI6MTUwNDYxMDg5MCwiZXhwIjoxNTA3MjAyODkwLCJpc3MiOiJodHRwczovL2FwaS5vcGVuY29sbGVjdGl2ZS5jb20iLCJzdWIiOjM5Mzl9.Bm4VaPJhcq2TBI8uZnWIfbH7-c3Iz6MroleDU5PhdwQ'
    conn = Faraday.new(url: 'https://opencollective.com',
                       headers: { 'Authorization' => "Bearer #{token}" })

    response = conn.get '/api/groups/testcollective/users'
    data = JSON.parse response.body
    # save the acquired json into plugin store
    ::PluginStore.set('discourse-opencollective-plugin','user_data', data)
  end

  def self.badges_grant!
    unless badge = Badge.find_by(name: BADGE_NAME)
      badge = Badge.create!(name: BADGE_NAME,
                           description: 'For the contributions made on OpenCollective ',
                           badge_type_id: 1)
    end
    retrieve=::PluginStore.get('discourse-opencollective-plugin','user_data')
    # Iterates through users
    retrieve.each do |user|
      email=user['email']
      dUser=User.find_by_email(email)
      if dUser==nil
        puts "User doesn't exist"
      else
        puts dUser.inspect
        BadgeGranter.grant(badge, dUser)
      end
    end
  end
end

after_initialize do
  module ::OpencollectivePlugin
    #this
    class GetDataJob < ::Jobs::Scheduled
      every 50.seconds

      def execute(args)
        OpencollectivePlugin.get_data!
      end
      end
    class GrantBadgeJob < ::Jobs::Scheduled
      every 50.seconds

      def execute(args)
        OpencollectivePlugin.badges_grant!
      end
    end
  end
end
