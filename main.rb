# Hack to use source code instead of hatchling.gem
$LOAD_PATH.unshift '../Hatchling/lib'

require 'hatchling'
require_relative 'src/dungeon'
require_relative 'src/battler'

Hatchling::Game.new.start
