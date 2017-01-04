#!/usr/bin/env ruby
# wlprogress: identify starts and stops of each module for a year

# Debugging:
# put 'binding.pry' where you want an interactive debugger to start
require 'pry'
require 'pathname'

##########################
# Standard option parsing
#
# By default, generate summary CSV file (start-end lessons every year)
# Optionally, generate long CSV file (every lesson every year)
#
require 'optparse'

options = {
  test: false,
  debug: false,
  verbose: false,
  top: '/Users/david.smyth/Code/Westlawn/_LESSON REPTS MASTER FILES/',
  long_csv: false
}

optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: wlprogress [options]'
  opts.on('-h', '--help', 'Show this help message') do ||
    puts opts
  end
  opts.on('-T', '--test', 'Test classes.') do ||
    options[:test] = true
  end
  opts.on('-d', '--debug', 'Enable debugging.') do ||
    options[:debug] = true
  end
  opts.on('-v', '--verbose', 'Enable verbose human readable output.') do ||
    options[:verbose] = true
  end
  opts.on('-t', '--top FOLDER', 'Top folder of student lesson files.') do |tf|
    options[:top] = tf
  end
  opts.on('-l', '--long', 'Generate long CSV file.') do ||
    options[:long_csv] = true
  end
end

begin
  optparse.parse!
  # Add symbols to 'required' array for each required argument
  required = [:top]
  missing = required.select { |reqd| options[reqd].nil? }
  raise OptionParser::MissingArgument, missing.join(', ') unless missing.empty?
  raise OptionParser::InvalidOption, ARGV unless ARGV.empty?
rescue OptionParser::MissingArgument, OptionParser::InvalidOption => e
  puts e
  puts optparse
  exit
end

TEST = options[:test].freeze
DEBUG = options[:debug].freeze
VERBOSE = options[:verbose].freeze
TOP = options[:top].freeze
CSV = !options[:long_csv].freeze
LONG = options[:long_csv].freeze
#
# End of standard option parsing
################################

class Lessons

  attr_reader :mod_start, :mod_final, :all

  def initialize
    @mod_start = [1, 13, 23, 32].freeze
    @mod_final = [12, 22, 31, 38].freeze
    @all = (1..38).to_a.freeze
    @module = []
    @module[0] = [].freeze
    @module[1] = (1..12).to_a.freeze
    @module[2] = (13..22).to_a.freeze
    @module[3] = (23..31).to_a.freeze
    @module[4] = (32..38).to_a.freeze
  end

  def module(lesson)
    @module.each_with_index do |mod,inx|
      return inx if mod.include? lesson
    end
    raise ArgumentError.new("Lesson #{lesson} is outside range of 1..38")
  end

  def self.test
    puts "Testing class #{self.name}"
    inst = Lessons.new
    cur_mod = 0
    inst.all.each do |l|
      if inst.mod_start.include? l
        cur_mod += 1
        puts "lesson #{l} start of Module #{inst.module(l)}"
      elsif inst.mod_final.include? l
        puts "lesson #{l} final of Module #{inst.module(l)}"
      else
        puts "lesson #{l} is in Module #{cur_mod}"
      end
      if cur_mod != inst.module(l)
        raise "wtf: cur_mod=#{cur_mod} but module(#{l}) is #{inst.module(l)}"
      end
    end
  end

end

class StudentsTakingExam
  STUDENT_ID_PATTERN = '[A-Z][A-Z][A-Z] [0-9][0-9][0-9][0-9][0-9]'
  def initialize(dir,lesson)
    @students = {}
    @lesson_file_pattern_a = "#{STUDENT_ID_PATTERN} YD #{format('%02d',lesson)}*.doc*"
    @lesson_file_pattern_b = "#{STUDENT_ID_PATTERN} YD #{lesson} *.doc*"

    dir.children.each do |f|
      fp = f.basename
      if fp.fnmatch?(@lesson_file_pattern_a) || fp.fnmatch?(@lesson_file_pattern_b)
        student = fp.to_s[0,9]
        puts "student #{student}" if TEST
        @students[student] = true
      end
    end
  end

  def length
    return @students.length
  end

  def self.test
    puts "Testing class #{self.name}"
    dir = Pathname.new("#{TOP}/LESSON REPTS 2003")
    inst = self.new(dir, 1)
    puts "unique students taking lesson 1 in 2003: #{inst.length}"
  end
end

class StudentTakingExam
end

class AnnualLessonsDir
end


class StudentsTakingExamsSummaryCSV
  def initialize( top = TOP )
    @top = Pathname.new(top)
    @lessons = Lessons.new
    @csv = []
  end

  def traverse_subdirs
    subdirs = @top.children.select(&:directory?)
    subdirs.each do |dir|
      year = extract_year(dir)
      @lessons.each do |lesson|
        @csv[year][lesson] = StudentsTakingExam.new(dir, lesson)
      end
    end
  end

  def extract_year(path)
    year = path.to_s[-4, 4].to_i
    puts "extracting year #{year}" if TEST or VERBOSE
    return year if 2003 <= year && year <= 2017
  rescue
    raise "Invalid directory name: #{path} Must end in 2003..2017"
  end

  def self.test
    puts "Testing class #{self.name}"
    inst = StudentsTakingExamsSummaryCSV.new
    inst.traverse_subdirs
  end
end

class StudentsTakingExamsLongCSV
end

class LessonFilesDir
end

class ProcessDirsMakeCsv
  def initialize
  end

  def process_dir(top)
  end
end

if __FILE__ == $PROGRAM_NAME
  # This block will only run if the script is the main file,
  # and not when it is load'd or require'd
  if TEST
    Lessons.test
    StudentsTakingExam.test
    StudentsTakingExamsSummaryCSV.test
  end

  if CSV
    csv = StudentsTakingExamsSummaryCSV.new
    puts csv
  end

  puts 'Done.' if VERBOSE
end
