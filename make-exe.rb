includes = ['assets', 'data']

require 'fileutils'
FileUtils.rm_rf('release')
Dir.mkdir('release')

system('ocra main.rb')
FileUtils.cp('main.exe', 'release')
File.delete('main.exe')

includes.each do |i|
	FileUtils.copy_entry(i, "release/#{i}")
end

puts 'Done. Release is published to /release.'