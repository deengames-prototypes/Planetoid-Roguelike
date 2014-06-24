# Hack to use source code instead of hatchling.gem
$LOAD_PATH.unshift '../Hatchling/lib'

require 'hatchling'
require_relative 'src/dungeon'
require_relative 'src/battler'
require_relative 'src/system/environment_system'

player = Entity.new({
	:health => HealthComponent.new(50, 0.02),
	:battle => BattleComponent.new({:strength => 7, :speed => 3 }),	
	# Total XP: 150, 400, 750, 1200, ...
	# XP diff: 150, 250, 350, 450, ...
	:experience => ExperienceComponent.new(lambda { |level| return (50*(level - 1)**2) + ((level - 1) * 100) })
})

g = Hatchling::Game.new(:player => player)
g.add_system(EnvironmentSystem.new)
g.start
