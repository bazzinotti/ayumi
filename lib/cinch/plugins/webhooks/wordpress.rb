# TODO
## Ignore events
## Comment Event
## Post Event
## Page event
## Config mapping path => blog_title
# p Utils::Uri.get_title_from_url(
#  "https://snestracker.wordpress.com/2016/04/05/first-people-to-compile-snes-tracker-debugger/")
#  .split(' | ')[0]


module Cinch::Plugins
  class Webhooks

    class Server < Sinatra::Base
      @submodule_name = "Wordpress"
      include Submodule

      module Wordpress
        # basically, only return true if the config explicitly sets active: false
        # lack of the value or parent key defaults to false
        def self.ignored?(event, data, blog_title)
          config_event = config[:blogs][blog_title][event]
          puts "MEME"
          puts config_event
          return false if !config_event
          return false unless active = config_event.key?('active')
          return true if !config_event['active'] && !config_event['active'].nil?
          false
        end
      end
    end


    module Wordpress
      def self.included(by)
        by.instance_exec do
          listen_to :wordpress_hook, method: :wordpress_hook
        end
      end

      def wordpress_hook(m, blog_title, data, event)
        @wordpress.send "get_#{event}", blog_title, data
      end

      def initialize(*args)
        super

        @wordpress = Wordpress.new(config, @bot)

        c = config
        Server.class_eval do
          c[:Wordpress]['blogs'].each do |k, v|
            post v['path'] do
              puts params
              event = params['hook']
              data = params
              blog_title = k
              return halt 202, "Ignored: #{event}" if Server::Wordpress::ignored?(event, data, blog_title)
              self.class.bot.handlers.dispatch(:wordpress_hook, nil, blog_title, data, event)
              return halt 200
            end
          end
        end
      end

      class Wordpress
        include Submodule

        def blog_channels(title)
          config[:blogs][title]['channels']
        end

        ##############
        # IRC Output #
        ##############

        def say(title, msg)
          blog_channels(title).each do |c|
            @bot.Channel(c).send msg
          end
        end

        #########
        # HOOKS #
        #########

        def get_comment_post(blog_title, data)
          puts "comment_post"
        end

        def get_publish_page(blog_title, data)
          puts "publish_page"
        end

        def get_publish_post(blog_title, data)
          puts "publish_post"
          response = "Test!!"

          say(blog_title, response)
        end
      end
    end
    include Wordpress
  end
end