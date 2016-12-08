class NukeNullsInPostingsLive < ActiveRecord::Migration[5.0]
  def change

    Posting.all.each do |posting|
      if posting.live.nil?
        posting.live = true
      end
    end

  end
end