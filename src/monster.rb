require 'hatchling/utils/logger'
require 'hatchling/component/interaction_component'

class Monster < Hatchling::Entity

	def initialize(x, y, type, target)
		@type = type.to_s		
		first_char = type[0]
		
		components = {}		
		color = nil
		before_move = nil
		
		# TODO: generate stats based on type; should this be data?
		# TODO: when you change these, change valid_types in dungeon.rb
		case type
			when :drone
				health = 14 + rand(14) # 2-4 attacks to die
				strength = 4 + rand(3) # 4-7 damage
				speed = 1
				experience = 10
				color = Color.new(0, 255, 0)
			when :hunter
				health = 10 + rand(10)
				strength = 10 + rand(10)
				speed = 2
				experience = 25
				color = Color.new(64, 100, 255)
			when :spitter
				health = 1
				strength = 0 # reduce to 0 when you add acid
				speed = 3
				experience = 64
				# TODO: acid damage fades as it fades
				# Base damage (max) is 35
				color = Color.new(255, 75, 255)							
				before_move = lambda { |pos| 
					acid = Entity.new({
						:lifetime => HealthComponent.new(5), # 5 moves
						:display => DisplayComponent.new(pos[:x], pos[:y], '%', Color.new(255, 0, 255)),
						:solid => false,
						:on_step => InteractionComponent.new(lambda { |target|
							target.get(:health).get_hurt(35) if target.has?(:health) && target.get(:health).is_alive?
							if target.has?(:name) && target.get(:name).downcase == 'player'
								message = 'Argh, acid!!'
							else
								message = "#{target.get(:name)} steps on acid!"
							end
							Game.instance.add_message(message);							
						})
					})
					Game.instance.add_entity(acid) if rand(0..100) <= 50 # % chance of acid
				}
			else
				raise "Not sure how to make a monster of type #{type}"
		end
		
		raise "Invalid monster: hp=#{health}, str=#{strength}, speed=#{speed} xp=#{experience}" if health.nil? || strength.nil? || speed.nil? || experience.nil?
		raise "Missing colour" if color.nil?
		
		components[:display] = DisplayComponent.new(x, y, first_char, color)
		components[:health] = HealthComponent.new(health)
		components[:battle] = BattleComponent.new({:strength => strength, :speed => speed, :target => target}, { :before_move => before_move })
		components[:name] = type.to_s.capitalize
		components[:experience] = experience
		
		super(components)
	end
end
