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
  full_csv: false
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
FULL = options[:long_csv].freeze
#
# End of standard option parsing
################################

# This class contains information about all the lessons
# in the Westlawn Yacht Design Course.
#
class Lessons
  attr_reader :all

  def initialize
    init_start_final_all
    init_module_map
  end

  def init_start_final_all
    @mod_start = [1, 13, 23, 32].freeze
    @mod_final = [12, 22, 31, 38].freeze
    @all = (1..38).to_a.freeze
  end

  def init_module_map
    @module = []
    @module[0] = [].freeze
    @module[1] = (1..12).to_a.freeze
    @module[2] = (13..22).to_a.freeze
    @module[3] = (23..31).to_a.freeze
    @module[4] = (32..38).to_a.freeze
  end

  def module(lesson)
    @module.each_with_index do |mod, inx|
      return inx if mod.include? lesson
    end
    raise ArgumentError, "Lesson #{lesson} is outside range of 1..38"
  end

  def start_or_final?(lesson)
    start?(lesson) || final?(lesson)
  end

  def start?(lesson)
    @mod_start.include? lesson
  end

  def final?(lesson)
    @mod_final.include? lesson
  end

  def self.test
    puts "Testing class #{name}"
    inst = Lessons.new
    inst.all.each do |l|
      msg = "lesson #{l} in module #{inst.module(l)}"
      msg += ' start' if inst.start?(l)
      msg += ' final' if inst.final?(l)
      puts msg
    end
  end
end

# This class generates a hash of student IDs representing all students that
# submitted a given lesson within a given directory. A directory corresponds
# to a year. Since a student may submit a given lesson several times, we
# only count unique students.
#
class StudentsTakingExam
  attr_reader :students

  STUDENT_ID_PATTERN = '[A-Z][A-Z][A-Z] [0-9][0-9][0-9][0-9][0-9]'.freeze

  def initialize(dir, lesson)
    @students = {}
    @pattern_a = "#{STUDENT_ID_PATTERN} YD #{format('%02d', lesson)}*.doc*"
    @pattern_b = "#{STUDENT_ID_PATTERN} YD #{lesson} *.doc*"

    dir.children.each do |f|
      fp = f.basename
      if fp.fnmatch?(@pattern_a) || fp.fnmatch?(@pattern_b)
        student = fp.to_s[0, 9]
        @students[student] = true
      end
    end
  end

  def length
    @students.length
  end

  def self.test
    puts "Testing class #{name}"
    dir = Pathname.new("#{TOP}/LESSON REPTS 2003")
    inst = new(dir, 1)
    puts "students: #{inst.students}"
    puts "unique students taking lesson 1 in 2003: #{inst.length}"
  end
end

# This class generates a hash of student IDs representing all students
# that submitted any exam in a given year.
#
class StudentsEnrolledInYear
  attr_reader :students

  def initialize(dir)
    @students = {}
    @pattern_c = "#{StudentsTakingExam::STUDENT_ID_PATTERN} YD *.doc*"

    dir.children.each do |f|
      fp = f.basename
      if fp.fnmatch? @pattern_c
        student = fp.to_s[0, 9]
        @students[student] = true
      end
    end
  end

  def length
    @students.length
  end

  def self.test
    puts "Testing class #{name}"
    dir = Pathname.new("#{TOP}/LESSON REPTS 2003")
    inst = new(dir)
    puts "students: #{inst.students}"
    puts "unique students enrolled in 2003: #{inst.length}"
  end
end

# This class is a spreadsheet with a header, and rows. Each row
# contains the number of students taking a lesson for each year.
# Columns are years. The first row is a header, the first two columns
# describe the lesson (descriptive text and lesson number).
#
class StudentsTakingExamsCSV
  YEARS = (2003..2016).freeze
  LESSONS = (1..38).freeze

  def initialize(top = TOP)
    @top = Pathname.new(top)
    @lessons = Lessons.new
    @csv = {}
    @enrollment = {}
  end

  def traverse_subdirs
    subdirs = @top.children.select(&:directory?)
    subdirs.each do |dir|
      year = extract_year(dir)
      @csv[year] = {}
      @lessons.all.each do |lesson|
        @csv[year][lesson] = StudentsTakingExam.new(dir, lesson).length
      end
      @enrollment[year] = StudentsEnrolledInYear.new(dir).length
    end
  end

  def csv(full = false)
    csv_header
    @lessons.all.each do |ls|
      csv_line(ls) if full || @lessons.start_or_final?(ls)
    end
    csv_total_enrollment
  end

  COL_0_1_FORMAT = '%-16s,%2s'.freeze
  COL_N_FORMAT = ', %4d'.freeze

  def csv_header
    header = format(COL_0_1_FORMAT, '', '')
    YEARS.each do |year|
      header += format(COL_N_FORMAT, year)
    end
    puts header
  end

  def csv_line_decription(ls)
    if @lessons.start? ls
      "Module #{@lessons.module(ls)} start"
    elsif @lessons.final? ls
      "Module #{@lessons.module(ls)} final"
    else
      "Module #{@lessons.module(ls)}"
    end
  end

  def csv_line(ls)
    col0 = csv_line_decription(ls)
    col1 = ls
    line = format(COL_0_1_FORMAT, col0, col1)
    YEARS.each do |year|
      line += format(COL_N_FORMAT, @csv[year][ls])
    end
    puts line
  end

  def csv_total_enrollment
    line = format(COL_0_1_FORMAT, 'active students', '')
    YEARS.each do |year|
      line += format(COL_N_FORMAT, @enrollment[year])
    end
    puts line
  end

  def extract_year(path)
    year = path.to_s[-4, 4].to_i
    puts "extracting year #{year}" if TEST || DEBUG || VERBOSE
    return year if YEARS.include? year
  rescue
    raise "Invalid directory name: #{path} Must end in 2003..2017"
  end

  def self.test
    puts "Testing class #{name}"
    inst = StudentsTakingExamsCSV.new
    inst.traverse_subdirs
    inst.csv(false)
  end
end

if __FILE__ == $PROGRAM_NAME
  # This block will only run if the script is the main file,
  # and not when it is load'd or require'd
  if TEST
    Lessons.test
    StudentsTakingExam.test
    StudentsEnrolledInYear.test
    StudentsTakingExamsCSV.test
  else
    csv = StudentsTakingExamsCSV.new
    csv.traverse_subdirs
    csv.csv(FULL)
  end

  puts 'Done.' if VERBOSE
end
