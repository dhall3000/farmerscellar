class AddRecurringPostingsFeatureEnableToWebsiteSettings < ActiveRecord::Migration
  def change
  	add_column :website_settings, :recurring_postings_enabled, :boolean, default: false, null: false
  end
end
