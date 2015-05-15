class AuthorizationSetup < ActiveRecord::Base
	serialize :response
	has_many :authorization_setup_tote_items
	has_many :tote_items, through: :authorization_setup_tote_items
end