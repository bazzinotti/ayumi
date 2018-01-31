require 'redis'

module Cinch::Plugins
  module Utils
    module HighScores
      module BackendInterface
        include Cinch::Plugins::Utils::Scores
        def print_highscores(m, n)
          response = ""
          nn = truncate_n(m,n)
          ts = top_highscores(nn)
          response << "┌─ " << "#{@owner.class_name} " \
            "Leaderboard" << " ─── " <<  "(Top #{ts.length})" << " ─" << "\n"
          ts.each_with_index do |us, ix|
            num_wins = us[1].to_i
	    last_win_time = Time.at(us[2]).strftime("%Y-%m-%d")
            response << "RANK #{ix+1}) #{us[0]} - #{num_wins} win#{"s" if num_wins > 1} (#{last_win_time})\n"
          end
          response << "\n" << "└ ─ ─ ─ ─ ─ ─ ─ ─\n"
          m.reply(response)
        end

        def highscore_table
          raise NotImplementedError, "Implement this method in a child class"
        end

	def get_highscore_time
	  raise NotImplementedError, "Implement this method in a child class"
	end

        def inc_highscore
          raise NotImplementedError, "Implement this method in a child class"
        end

        def rem_highscore
          raise NotImplementedError, "Implement this method in a child class"
        end

        def top_highscores
          raise NotImplementedError, "Implement this method in a child class"
        end
      end

      class Redis
        include BackendInterface
        include Bazz::Utils::Scores::Redis

        def initialize(owner)
          @owner = owner
        end

        def highscore_table
          "#{@owner.class.plugin_name}:highscores"
        end

        def highscore_time(user)
          "#{highscore_table}:#{user}:time"
        end

	# Returns UTC time-since-epoch timestamp as a string
	def get_highscore_time(user)
	  Bazz::Utils::Redis.get(highscore_time(user))
	end

	# increments a user's score by 1
        def inc_highscore(user)
          inc_score(highscore_table, user)
          # update time
          Bazz::Utils::Redis.set(highscore_time(user), Time.new.to_i.to_s)
        end

        def rem_highscore(user)
          rem_score(highscore_table, user)
        end

        def highscores_sort(real_scores, users, last_score)
          # check if there are scores to sort!!
          return real_scores if users.size == 0
          if users.size > 1
            # let's do fun sorting!!
            user_time = []
            users.each do |u|
              user_time << [u, get_highscore_time(u).to_i]
            end
            # sort it
            puts user_time.sort_by(&:last)
            user_time.sort_by(&:last).each do |u, t|
              real_scores << [u, last_score, t]
            end
          else
            # if not, just add it to real_scores
            real_scores << [users[0], last_score, get_highscore_time(users[0]).to_i]
          end
          real_scores
        end

        def top_highscores(n)
          scores = top_scores(highscore_table, n)
          return scores if scores.size == 1
          real_scores = []
          last_user, last_score = scores[0]
          users = []
          scores.each do |user, score|
            # check if this score is already present
            if last_score != score
              real_scores = highscores_sort(real_scores, users, last_score)
              users.clear
            end
            users << user
            last_score = score
          end
          highscores_sort(real_scores, users, last_score)
        end
      end
    end
  end
end
