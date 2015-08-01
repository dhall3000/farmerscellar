class AddNotesToAccessCodes < ActiveRecord::Migration
  def change
    add_column :access_codes, :notes, :text
  end
end
