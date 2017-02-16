class AddSendTimeColumnToEmail < ActiveRecord::Migration[5.0]
  def change
    add_column :emails, :send_time, :datetime
  end
end