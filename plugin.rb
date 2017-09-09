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
    token=SiteSetting.opencollective_access_token
    collective=SiteSetting.opencollective_collective_name

    if token=="" or collective==""
      puts "Fetching users from opencollective failed!"
      puts "Please configure settings.yml for the opencollective plugin"
      ::PluginStore.set('discourse-opencollective-plugin','user_data', nil)
      return
    end
    conn = Faraday.new(url: 'https://opencollective.com',
                       headers: { 'Authorization' => "Bearer #{token}" })

    response = conn.get "/api/groups/#{collective}/users"
    data = JSON.parse response.body
    # save the acquired json into plugin store
    ::PluginStore.set('discourse-opencollective-plugin','user_data', data)
  end

  def self.badges_grant!
    retrieve=::PluginStore.get('discourse-opencollective-plugin','user_data')
    if retrieve==nil
      puts "Granting badges for OpenCollective users failed!"
      return
    end
    unless badge = Badge.find_by(name: BADGE_NAME)
      badge = Badge.create!(name: BADGE_NAME,
                           description: 'For the contributions made on OpenCollective ',
                           badge_type_id: 1)
    end

    # Iterates through users
    retrieve.each do |user|
      email=user['email']
      dUser=User.find_by_email(email)
      if dUser!=nil
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
