require 'hatchling'
require_relative 'monster'

include Hatchling

class Battler
	def resolve_attacks(attacks)
		messages = []
		dead_entities = []
		
		attacks.each do |a|
			attacker = a[:attacker]
			target = a[:target]
						
			damage = attacker.get(:battle).strength
			health = target.get(:health)			
			health.get_hurt(damage)
									
			message = "#{attacker.name} attacks #{target.name} for #{damage} damage!"
			message += " #{target.name} dies!" if !health.is_alive?
			messages << message
		end
		return {:messages => messages}
	end
end
