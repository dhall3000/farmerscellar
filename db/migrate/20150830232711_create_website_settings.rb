class CreateWebsiteSettings < ActiveRecord::Migration
  def change
    create_table :website_settings do |t|
      t.boolean :new_customer_access_code_required

      t.timestamps null: false
    end
  end
end
