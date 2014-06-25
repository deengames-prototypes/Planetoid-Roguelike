require_relative 'monster'

include Hatchling

### A randomly-generated dungeon. This code is game specific.
class Dungeon
	attr_reader :stairs, :walls # TODO: replace with generic list
	attr_reader :perimeter, :width, :height, :start_x, :start_y, :floor 
	attr_accessor :entities # the new generic list, see TODO above
	
	
	def initialize(floor, player)				
		@floor = floor
		@width = 80
		@height = 22
		@perimeter = true
		@entities = []
		@player = player
		
		if (!player.nil?)
			generate_topology
			generate_monsters
		end
	end
	
	def add_wall(x, y)
		@walls << [x, y]
	end
	
	
	def is_valid_move?(move)
		# Exclude stairs. We want: all_entities - @stairs,
		# but we have to translate types.
		stairs = []
		@stairs.each do |s|
			stairs << { x: s['x'], y: s['y'] }
		end
		
		blocking_entities = all_entities - stairs
		blocking_entities = blocking_entities.find { |b| b[:x] == move[:x] && b[:y] == move[:y] && (b[:solid].nil? || b[:solid] == true) }
		return blocking_entities.nil? || blocking_entities.count == 0
	end
	
	private 
	
	# TODO: very expensive type translation/standardization.
	def all_entities
		to_return = []
		
		@stairs.each do |s|
			to_return << { :x => s['x'], :y => s['y'], :solid => false }
		end
		
		@entities.each do |e|
			to_return << { :x => e.get(:display).x, :y => e.get(:display).y, :solid => e.has?(:solid) ? e.solid : false }			
		end
		
		@walls.each do |w|
			to_return << { :x => w[0], :y => w[1] }			
		end
		
		return to_return
	end
	
	def generate_monsters
		# Smartly pick monsters based on a weighted average, which starts
		# at 50% on the floor they appear, and decreases linearly by 5%/floor.		
		start_probability = 0.5
		prob_decrease_per_floor = 0.05 # todo: varies per type?
		
		# First, what monsters are valid on this floor?
		probability = { :drone => start_probability - ((floor - 1) * prob_decrease_per_floor) }
		probability[:hunter] = start_probability - ((floor - 2) * prob_decrease_per_floor) if floor >= 2
		probability[:spitter] = start_probability - ((floor - 3) * prob_decrease_per_floor) if floor >= 3		
		
		# 5-10  monsters
		m = rand(5) + 5
		
		(1..m).map { |i|
			# random probability
			p = rand(0.0 .. 1.0)
			type = nil
			# Find all monster candidates with >= p as their probability
			# Randomly pick one.
			candidates = []
			probability.map { |kvp|
				candidates << kvp[0] if p >= kvp[1]				
			}
						
			# If there were no candidates, default to random selection
			# from types available on this floor
			candidates << probability.keys.sample if candidates.length == 0
			
			type = candidates.sample
			coordinates = find_empty_spot
			@entities << Monster.new(coordinates[:x], coordinates[:y], type, @player)			
		}
	end
	
	def generate_topology
		# Fill 'er up!
		@walls = []
		new_walls = {}		
		
		(0 .. @width - 1).each do |x|
			new_walls[x] = {}
			(0 .. @height - 1).each do |y|
				new_walls[x][y] = true
			end
		end
				
		rooms = []
		# number of rooms to make		
		target = rand(10) + 30		
		
		while (rooms.length < target)
			radius = rand(2) + 3
			x = rand(@width)
			y = rand(@height)			
			make_circle(x, y, radius, new_walls, false)
			last_seen = {:x => x, :y => y} unless 
				# Perimeter wall
				(@perimeter == true && (x == 0 || y == 0 || x == @width - 1 || y == @height - 1)) ||
				# Filled in here
				new_walls[x][y] == true
			rooms << {:x => x, :y => y, :radius => radius}			
		end		
		
		g = GraphOperator.new(@width, @height, rooms, new_walls, last_seen)
		g.connect_unconnected_rooms!()

		# Convert to map data		
		new_walls.each do |wall_x, map|
			map.each do |wall_y, is_wall| 
				@walls << [wall_x, wall_y] if is_wall == true || is_on_perimeter?(wall_x, wall_y)
			end
		end
		
		@start_x = last_seen[:x]
		@start_y = last_seen[:y]
		
		# Populate stairs down
		target = {:x => last_seen[:x], :y => last_seen[:y]}
		while (
			(target[:x] == @start_x && target[:y] == @start_y) || # Not on the player start
			(walls.include?([target[:x], target[:y]]))  || # Not on a wall
			(g.distance(target[:x], target[:y], @start_x, @start_y) <= 225) # Not too close; 15 squares
		) do
			room = rooms[rand(rooms.length)]
			target[:x] = room[:x]
			target[:y] = room[:y]
		end
		
		@stairs = [
			{'x' => target[:x], 'y' => target[:y]},
			{'x' => @start_x, 'y' => @start_y, 'direction' => 'up'}
		]
	end
	
	def make_circle(x, y, radius, walls, filled)
		random_point = nil
		
		walls[x][y] = false						
		(x - radius .. x + radius).each do |i|
			(y - radius .. y + radius).each do |j|
				if (i - x)**2 + (j - y)**2 <= radius**2 && i >= 0 && j >= 0 && i < @width && j < @height then					
					walls[i][j] = filled					
					# Randomly pick a perimeter point and generate a filled circle
					# The source of the magic number 30: If the radius is 3, there
					# are roughly 12 perimeter points; if we want this to happen once
					# every three circles, that's 1/36. 1/30 looks good.
					# random_point = {:x => i, :y => j} if rand(30) == 0 && !filled
				end
			end
		end
		
		if !random_point.nil?
			make_circle(random_point[:x], random_point[:y], radius / 2, walls, true)
		end
	end
	
	def is_on_perimeter?(x, y)
		return @perimeter == true && (x == 0 || y == 0 || x == @width - 1 || y == @height - 1)
	end
	
	# Find an empty spot: no stairs, nothing is close by (see in_proximity)
	def find_empty_spot	
		check_against = []
		
		# Why isn't this standardized?
		@stairs.each do |s|
			check_against << { :x => s['x'], :y => s['y'] }
		end
		
		@entities.each do |e|
			check_against << { :x => e.get(:display).x, :y => e.get(:display).y }			
		end
		
		x = check_against[0][:x]
		y = check_against[0][:y]
				
		while check_against.include?({:x => x, :y => y}) || in_proximity(x, y, check_against, 5) || walls.include?([x, y]) do
			x = rand(@width)
			y = rand(@height)
		end
		
		return {:x => x, :y => y}
	end
	
	# Make sure (x, y) is within range tiles of entities
	def in_proximity(x, y, entities, range)
		entities.each do |e|			
			distance = (e[:x] - x)**2 + (e[:y] - y)**2			
			if distance <= range**2 then
				return true 
			end
		end
		
		return false
	end
end

############# helper class ############

class GraphOperator	
	def initialize(width, height, rooms, new_walls, player_start)
		@width = width
		@height = height
		@rooms = rooms
		@new_walls = new_walls
		@player_start = player_start
	end
	
	def connect_unconnected_rooms!()
		# What are we doing here?
		# 1) Create a spanning tree of all rooms
		# 		For each room, find the closest room
		# 2) For each unconnected room, tunnel to the closest room
		# NB: Start at the starting room (contains the player)
		
		# Flood-fill the map
		empty_tiles = find_empty_tiles()
		
		# Assign: connected or not?
		connected_rooms = []
		unconnected_rooms = []		
		
		@rooms.each do |r|
			if empty_tiles.include?({:x => r[:x], :y => r[:y]}) then
				connected_rooms << r
			else
				unconnected_rooms << r
			end
		end
		
		unconnected_rooms.each do |r|
			closest = find_closest_room(r, connected_rooms)
			tunnel(r[:x], r[:y], closest[:x], closest[:y])
			connected_rooms << r
		end
	end
		
	# Returns a bunch of elements like {:x => i, :y => j}
	def find_empty_tiles()
		empty_tiles = []
		visited_tiles = {}				
		queue = [{:x => @player_start[:x], :y => @player_start[:y]}]
				
		(0 .. @width).each do |x|
			visited_tiles[x] = {}
			(0 .. @height).each do |y|
				visited_tiles[x][y] = nil
			end
		end		
		
		while (queue.length > 0) do
			current = queue.pop			
			x = current[:x]
			y = current[:y]
			visited_tiles[x][y] = true			
			empty_tiles << current if @new_walls[x][y] == false
			
			# Queue conditions:
			# 1) Position is on the map
			# 2) Space is unoccupied
			# 3) Space was never visited
			# 4) Space is not in queue
			spot = {:x => x - 1, :y => y}
			queue << spot if x - 1 > 0 && @new_walls[x - 1][y] == false && visited_tiles[x-1][y].nil? && !queue.include?(spot)
			spot = {:x => x, :y => y - 1}
			queue << spot if y - 1 > 0 && @new_walls[x][y - 1] == false && visited_tiles[x][y-1].nil? && !queue.include?(spot)
			spot = {:x => x + 1, :y => y}
			queue << spot if x + 1 < @width && @new_walls[x + 1][y] == false && visited_tiles[x+1][y].nil? && !queue.include?(spot)
			spot = {:x => x, :y => y + 1}
			queue << spot if y + 1 < @height && @new_walls[x][y + 1] == false && visited_tiles[x][y+1].nil? && !queue.include?(spot)			
		end

		return empty_tiles		
	end	
		
	# Tunnel along a line, filling in gaps as necessary
	def tunnel(start_x, start_y, stop_x, stop_y)		
		m = (0.0 + stop_y - start_y) / (stop_x - start_x)		
		last_spot = nil		
		
		if m.abs < 1
			# Tunnel horizontally			
			if stop_x < start_x						
				start_x, stop_x = stop_x, start_x
				start_y, stop_y = stop_y, start_y				
			end
			
			(start_x .. stop_x).each do |x|
				# y - y1 = m(x - x1)
				# y = m(x-x1) + y1
				y = m * (x - start_x) + start_y
				@new_walls[x][y.round] = false if x < @width && y.round < @height		
				
				if !last_spot.nil?
					d = (x - last_spot[:x]).abs + (y.round - last_spot[:y]).abs
					if d >= 1.5
						min = [last_spot[:y], y.round].min
						max = [last_spot[:y], y.round].max												
						(min .. max).each do |j|							
							if (m.round != 0)
								i = ((j - last_spot[:y]) / m.round) + x
							else
								i = x
							end							
							@new_walls[i.round][j] = false if i.round < @width && j < @height	
						end
					end
				end
				
				
				last_spot = {:x => x, :y => y.round}
			end
		elsif m.abs > 1
			# Tunnel vertically			
			if stop_y < start_y	
				start_x, stop_x = stop_x, start_x
				start_y, stop_y = stop_y, start_y				
			end
			
			(start_y .. stop_y).each do |y|
				# y - y1 = m(x - x1)
				# (y - y1)/m = x-x1
				# (y-y1)/m  +x1 = x
				x = ((y - start_y) / (0.0 + m)) + start_x
				@new_walls[x.round][y] = false if x.round < @width && y < @height	
				
				if !last_spot.nil?
					d = (x - last_spot[:x]).abs + (y.round - last_spot[:y]).abs					
					if d >= 1.5
						min = [last_spot[:x], x.round].min
						max = [last_spot[:x], x.round].max
						(min .. max).each do |i|
							j = m.round * (i - last_spot[:x]) + y
							@new_walls[i][j.round] = false if i < @width && j.round < @height	
						end
					end
				end
								
				last_spot = {:x => x.round, :y => y}
			end
		else # m == 1			
			if stop_x < start_x						
				start_x, stop_x = stop_x, start_x
				start_y, stop_y = stop_y, start_y
			end

			y_increment = (m > 0 ? 1 : -1)
			y = start_y
			
			(start_x .. stop_x).each do |x|				
				# We're at x, y and want to get to x+1, y+1
				# So delve out x+1, y too
				@new_walls[x][y] = false if x < @width && y < @height	
				@new_walls[x][y + y_increment] = false if x < @width && y + y_increment < @height	
				y += y_increment				
			end
		end
	end
	
	def find_closest_room(room, rooms)
		min_distance = 999999
		min_room = nil
		
		rooms.each do |r|
			next if r == room || (room[:x] == r[:x] && room[:y] == r[:y])
			d = distance(r[:x], r[:y], room[:x], room[:y])
			if d < min_distance
				min_distance = d
				min_room = r
			end
		end
		
		return min_room
	end
	
	def distance(x1, y1, x2, y2)
		return ((x2 - x1)**2 + (y2 - y1)**2)
	end
end
