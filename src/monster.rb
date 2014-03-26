require 'model/entity'
require 'component/health_component'
require 'component/display_component'
require 'component/battle_component'
require 'utils/color'

class Monster < Entity

	def initialize(x, y, type)
		@type = type.to_s
		first_char = type[0]
		
		components = {}
		components[:display] = DisplayComponent.new(x, y, first_char, Color.new(0, 255, 0))
		
		# TODO: generate stats based on type
		case type
		when :drone
			health = 15 + rand(5)
			strength = 2 + rand(1)
			speed = 1
		else
			raise "Not sure how to make a monster of type #{type}"
		end
		
		components[:health] = HealthComponent.new(health)
		components[:battle] = BattleComponent.new(strength, speed)
				
		super(components)
	end
end
