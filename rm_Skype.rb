#!/usr/bin/env ruby
#
require 'FileUtils'

skype_files = `find . -name \*Skype\*`
skype_files.each_line do |file|
  file.chomp!
  if File.exist? file
    puts "#{file} exist? #{File.exist? file} type=#{File.ftype file} size=#{File.size file}"
    FileUtils.rm_rf file
  else
    puts "#{file} exist? #{File.exist? file}"
  end
  puts "Could not delete #{file}" if File.exist? file
end
