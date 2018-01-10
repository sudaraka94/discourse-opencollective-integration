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

  def self.badges_grant!(user)
    unless badge = Badge.find_by(name: BADGE_NAME)
      badge = Badge.create!(name: BADGE_NAME,
                           description: 'For the contributions made on OpenCollective ',
                           badge_type_id: 1)
    end
    BadgeGranter.grant(badge, user)
  end

  def self.seed_group!
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
    ::PluginStore.set('discourse-opencollective-plugin','backer_group_id',group_id )
    return default_group
  end

  def self.add_backers_to_group!(user)
    group_id=::PluginStore.get('discourse-opencollective-plugin','backer_group_id')
    if group_id==nil
       group=seed_group!
    else
      group = Group.find_by id: group_id.to_i
      if group==nil
        group=seed_group!
      end
    end

    group.add user
  end


  def self.sync!
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
    # Iterates through users
    data.each do |user|
      email=user['email']
      dUser=User.find_by_email(email)

      if dUser!=nil
        if user['role']=="BACKER"
          badges_grant!(dUser)
          add_backers_to_group!(dUser)
        end
      end
    end
  end

end

after_initialize do
  module ::OpencollectivePlugin
    class GrantBadgeJob < ::Jobs::Scheduled
      every 1.day

      def execute(args)
        OpencollectivePlugin.sync!
      end
    end
  end
end
