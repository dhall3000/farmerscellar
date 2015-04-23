class UnitKind < ActiveRecord::Base
  belongs_to :unit_category
  has_many :postings
end
