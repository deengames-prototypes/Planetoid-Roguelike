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
			
			if attacker.has?(:battle) then
				damage = attacker.get(:battle).strength
				health = target.get(:health)
				health.get_hurt(damage)
										
				message = "#{attacker.name} attacks #{target.name} for #{damage} damage!"
				if !health.is_alive? then
					message += " #{target.name} dies!" 
					dead_entities << target	
				end
				messages << message
			end
		end
		return {:messages => messages, :remove_entities => dead_entities}
	end
end
