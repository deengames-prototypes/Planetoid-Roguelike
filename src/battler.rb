require_relative 'monster'

include Hatchling

class Battler
	def resolve_attacks(attacks)
		messages = []		
		
		attacks.each do |a|
			attacker = a[:attacker]
			target = a[:target]
			# Attacks are already ordered. By the time your turn comes, you may
			# already be dead. Check and verify.
			if (attacker.get(:health).is_alive?) then
				damage = attacker.get(:battle).strength
				health = target.get(:health)			
				health.get_hurt(damage) if damage > 0

				message = "#{attacker.name} attacks #{target.name} for #{damage} damage!"
				if !health.is_alive?
					message += " #{target.name} dies!" 
					if attacker.name.downcase == 'player' then
						attacker.get(:experience).gain_experience(target.experience)						
					end
				end
				messages << message
			end
		end
		return {:messages => messages}
	end
end
