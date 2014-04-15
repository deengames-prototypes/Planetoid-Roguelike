# Used to keep relative paths DRY
require 'test/unit'

$LOAD_PATH.unshift '../../Hatchling/lib'
require 'hatchling'

TEST_ROOT = Dir.pwd
Dir.chdir('..')
SOURCE_ROOT = Dir.pwd
