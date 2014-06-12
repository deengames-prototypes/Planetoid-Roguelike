# Hack to use source code instead of hatchling.gem
$LOAD_PATH.unshift '../Hatchling/lib'

require 'hatchling'
require_relative 'src/dungeon'
require_relative 'src/battler'

player = Entity.new({
	:health => HealthComponent.new(50, 0.02),
	:battle => BattleComponent.new({:strength => 7, :speed => 3 }),	
	:experience => ExperienceComponent.new(lambda { |level| return (level**2 * 50) + (level * 100) })
})

g = Hatchling::Game.new(:player => player)
g.start
