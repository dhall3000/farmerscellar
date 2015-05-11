class AuthorizationSetupToteItem < ActiveRecord::Base
  belongs_to :authorization_setup
  belongs_to :tote_item
end
