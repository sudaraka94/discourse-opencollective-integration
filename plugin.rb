# name: opencollective-plugin
# about: This is intended to be a feature-rich plugin for opencollective-discourse integration
# version: 0.1
# authors: Sudaraka Jayathilaka
# url: https://github.com/sudaraka94/opencollective-plugin.git

enabled_site_setting :opencollective_enabled

require 'net/http'
require 'uri'
require 'json'

module ::OpencollectivePlugin
  BADGE_NAME ||= 'OpenCollective Donator'.freeze

  def self.badges_grant!
    token=SiteSetting.opencollective_access_token
    collective=SiteSetting.opencollective_collective_name

    if token=="" or collective==""
      puts "Fetching users from opencollective failed!"
      puts "Please configure settings in your admin panel"
      return
    end

    conn = Faraday.new(url: 'https://opencollective.com',
                       headers: { 'Authorization' => "Bearer #{token}" })

    response = conn.get "/api/groups/#{collective}/users"
    data = JSON.parse response.body

    if data==nil
      puts "Granting badges for OpenCollective users failed!"
      return
    end
    unless badge = Badge.find_by(name: BADGE_NAME)
      badge = Badge.create!(name: BADGE_NAME,
                           description: 'For the contributions made on OpenCollective ',
                           badge_type_id: 1)
    end

    # Iterates through users
    data.each do |user|
      email=user['email']
      dUser=User.find_by_email(email)

      if dUser!=nil
        BadgeGranter.grant(badge, dUser)
        add_users_to_groups!(dUser)
      end
    end
  end

  def self.add_users_to_groups!(user)
     puts "run"
     group_id=::PluginStore.get('discourse-opencollective-plugin','group_id')
     if group_id==nil
       default_group = Group.new(
           name: 'Backer',
           visibility_level: Group.visibility_levels[:public],
           primary_group: true,
           title: 'Open Collective Backer',
           flair_url: 'https://opencollective.com/public/images/oc-logo-icon.svg',
           bio_raw: 'Open Collective Backers are added to this user group',
           full_name: 'Open Collective Backer'
       )

       default_group.save!
       group_id=default_group.id.to_s
       ::PluginStore.set('discourse-opencollective-plugin','group_id',group_id )
     end

     group = Group.find_by id: group_id.to_i
     group.add user
     puts "saved"
  end

end

after_initialize do
  module ::OpencollectivePlugin
    class GrantBadgeJob < ::Jobs::Scheduled
      every 1.day

      def execute(args)
        OpencollectivePlugin.badges_grant!
      end
    end
  end
end
