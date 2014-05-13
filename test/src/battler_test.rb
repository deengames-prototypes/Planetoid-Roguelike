require_relative '../test_config'
require_relative "#{SOURCE_ROOT}/src/battler"

class BattlerTest < Test::Unit::TestCase
	
	def test_gimmie_code_coverage_yo
		Battler.new
	end
end
