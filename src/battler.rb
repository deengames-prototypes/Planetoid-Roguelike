require 'hatchling'
require_relative 'monster'

include Hatchling

class Battler
	def resolve_attacks(attacks)
		messages = []
		attacks.each do |a|
			attacker = a[:attacker]
			target = a[:target]
			
			if attacker.has?(:battle) then
				damage = attacker.get(:battle).strength
				target.get(:health).get_hurt(damage)				
				messages << "#{attacker.name} attacks #{target.name} for #{damage} damage!"
			end
		end
		return {:messages => messages}
	end
end
