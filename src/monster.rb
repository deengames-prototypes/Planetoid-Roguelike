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
			when :goopie
				health = 1
				strength = 0
				speed = 3
				experience = 63
				color = Color.new(255, 255, 0)
				on_death = lambda { 
					splatter(:goop)
				}
			when :spitter
				health = 1
				strength = 0
				speed = 3
				experience = 126
				color = Color.new(255, 75, 255)
				before_move = lambda { |pos| 					
					Game.instance.add_entity(make_acid(pos[:x], pos[:y])) if rand(0..100) <= 30 # % chance of acid
				}
				before_attack = lambda { |target| 
					self.get(:health).get_hurt(1) # self-destruct
					Game.instance.add_message("A splitter explodes!");
				}
				on_death = lambda { 
					splatter(:acid)
				}
			else
				raise "Not sure how to make a monster of type #{type}"
		end
		
		raise "Invalid monster of #{type}: hp=#{health}, str=#{strength}, speed=#{speed} xp=#{experience}" if health.nil? || strength.nil? || speed.nil? || experience.nil?
		raise "Missing colour for #{type}" if color.nil?
		
		components[:display] = DisplayComponent.new(x, y, first_char, color)
		components[:health] = HealthComponent.new(health, nil, { :on_death => on_death })
		components[:battle] = BattleComponent.new(
			{:strength => strength, :speed => speed, :target => target},
			{ :before_move => before_move, :before_attack => before_attack })
		components[:name] = type.to_s.capitalize
		components[:experience] = experience
		
		super(components)
	end
	
	def splatter(type)
		pos = self.get(:display)
		
		method = nil
		size = 0
		
		case type
			when :acid
				method = lambda { |x, y| make_acid(x, y) } 
				size = 2
			when :goop
				method = lambda { |x, y| make_goop(x, y) }
				size = 3
			else
				raise "Not sure how to splatter #{type} particles"				
		end
		
		# Theoretically, generate random points in a circle originating at us.
		# Technically, just iterate over a 3x3 grid and randomly pick points.
		(pos.y - size .. pos.y + size).each do |y|
			(pos.x - size .. pos.x + size).each do |x|
				
				# TODO: how do I check for bounds/entities and not splurt accordingly?
				particle = method.call(x, y) if (x - pos.x)**2 + (y - pos.y)**2 <= size**2 && rand(0..100) <= 50
				Game.instance.add_entity(particle) unless particle.nil?				
			end
		end
	end
	
	def make_acid(x, y)
		return Entity.new({
			:lifetime => HealthComponent.new(rand(5..20)), # fade away after 10-20 moves
			:display => DisplayComponent.new(x, y, '%', Color.new(255, 0, 255)),
			:solid => false,
			:on_step => InteractionComponent.new(lambda { |target|
				# Must be named, healthy, alive, non-spitter
				if target.has?(:name) && target.get(:name) != 'Spitter' && target.has?(:health) && target.get(:health).is_alive?
					# TODO: acid damage fades as it fades
					# Base damage (max) is 35				
					target.get(:health).get_hurt(35)
					if target.get(:name).downcase == 'player'
						message = 'Argh, acid!!'
					else
						message = "#{target.get(:name)} steps on acid!"
					end
					Game.instance.add_message(message);
				end	
			})
		})
	end
	
	def make_goop(x, y)
		return Entity.new({
			:lifetime => HealthComponent.new(rand(5..10)), # fade away after 5-10 moves
			:display => DisplayComponent.new(x, y, '%', Color.new(255, 192, 0)),
			:solid => false,
			:on_step => InteractionComponent.new(lambda { |target|
				# Must be named, healthy, alive, non-spitter
				if target.has?(:name) && target.has?(:health) && target.get(:health).is_alive?
					# nominal damage; triggers stuff, like splitters.
					target.get(:health).get_hurt(5)
					if target.get(:name).downcase == 'player'
						message = 'You step in sticky goop. Ouch!'
					else
						message = "#{target.get(:name)} winces and wades through goop!"
					end
					Game.instance.add_message(message);
				end	
			})
		})
	end
end
