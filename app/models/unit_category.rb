class UnitCategory < ActiveRecord::Base
	has_many :unit_kinds
	has_many :postings
end
