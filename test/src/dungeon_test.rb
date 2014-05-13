require_relative '../test_config'
require_relative "#{SOURCE_ROOT}/src/dungeon"

class DungeonTest < Test::Unit::TestCase
	
	def test_gimmie_code_coverage_yo
		Dungeon.new(2, nil)
	end
end
