require 'test_helper'
require 'utility/rake_helper'

class ModelTestAncestor < ActiveSupport::TestCase

  def teardown
    travel_back
  end

end