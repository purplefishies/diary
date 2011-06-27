require 'rake'
require 'diary_model'

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Going to modify it so that I can record how
# I actually leave in tasks in the journal that
# are completed, but their completion date is less than
# tomorrow..............................................................DONE!
#
#
# 2. List only tasks in the short view that aren't completed............
#
# 3.
#
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
namespace :diary do 


MAIN_DIRECTORY = ENV["HOME"] + "/Schedule/"
DBFILE = ENV["HOME"] + "/.notes.db"

def currentDay
  time = Time.new()
  MAIN_DIRECTORY + time.strftime("%Y/%b/%m_%d_%y.yml")
end

desc "First Task"
task :updateProject do |t|
  curfile = currentDay()
    ActiveSupport::Deprecation.silenced = true
    ActiveRecord::Base.establish_connection( :adapter => "sqlite3", :dbfile => DBFILE )
  if File.file?(curfile )
    
  else
    
  end

end

desc "A test"
task :test do |t|
  puts ENV["DIARY"]
end


desc "Add Diary Entry"
task :addDiary do |t|
#  ActiveSupport::Deprecation.silenced = true
#  ActiveRecord::Base.establish_connection( :adapter => "sqlite3", :dbfile => ".notes.db" )
  connect()
  if ENV["DIARY"].empty?
    throw Exception.new("Need to have specified DIARY=\"??\"" )
  end
  c = Category.find(:all, :conditions => ['name like ?','%iary%'] ).first

  if !c.nil? && ENV["DIARY"]
    t = Task.new(:entry => ENV["DIARY"] )
    t.start = Time.now
    t.category = c 
    t.save
  end
  
end

desc "Add Task"
task :addTask, [:task,:dueDate,:expected,:parent] do |t,args|
  connect()
  b = Task.new(:entry   => args.task,
               :due     => ( args.dueDate.nil? ? nil : Date.parse( args.dueDate) ),
               :expcomplete => ( args.expected.nil? ? nil : args.expected ),
               :parents => ( Task.find(:all, :conditions => { :id => args.parent })
                            ),
               :start   => Time.now
               )
  b.category = Category.find(:all, :conditions => ['name = ?',"task"] ).first
  b.save
end


desc "List Tasks"
task :listTasks , [:numlist] do |t, args|
  args.default( :numlist => false )
  connect()
  if args.numlist
    connect()
    c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
    entries = getTasks().find_all { |i| i.completed.nil? }
    entry = entries.map {|i| "#{i.id}: #{i.entry}" }.join("\n")
  else
    entries = getTasks().find_all { |i| i.completed.nil? }
    puts "Entries was of length #{entries.length}"
    entry = formatTasks( entries )
  end
  puts entry
end

def findTask(id)
  connect()
  c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
  return Task.find(:all, 
                   :conditions => {
                     :category_id => c.id,
                     :id => id
                   }
                   ).first
end

def findDiaryEntries()
  connect()
  c = Category.find(:all, :conditions => ['name = ?',"diary"] ).first
#   puts "Founs category #{c}"
  return Task.find(:all,
                   :conditions => { 
                     :category_id => c.id,
                   }
                   )
end

desc "Deletes a task based on number"
task :deleteTask, [:taskID] do |t,args|
  b = findTask( args.taskID )
#  puts b.new_to_yaml("")
  b.destroy
end

desc "Delete last diary entry"
task :deleteLastDiary do |t|
  entry = findDiaryEntries().find_all {  |t|
    t.start >= Date.today.to_time 
  }.last
  if !entry.nil?
    entry.destroy
  end
#  puts entry.to_yaml
end


desc "Mark a task as completed"
task :completeTask, [:taskID] do |t,args|
  b = findTask( args.taskID )
  b.completed = Time.now
  b.save
end

desc "getTask matching"
task :getTask , [:regex] do |t,args|
  args.with_defaults( :regex => ".*" )

  regex = Regexp.new( args.regex )

  if ENV["REGEX"] 
    regex = Regexp.new( ENV["REGEX"] )
  end
  connect()
  c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
  puts selectTasksMatching( regex ).map { |i| 
    i.new_to_yaml("")
  }

end

desc "Modify task"
task :modifyTask, [:action, :tagnum] do |t|
  if args.action.nil?
    throw Exception.new("Action must be either 'delete' or 'modify'")
  end
  
end

#
#
#
def getTasks(*args)
  if args.empty?
    cat = "task"
  else
    cat = args[0]
  end
  c = Category.find(:all, :conditions => ['name = ?', cat ] ).first
  alltasks=  Task.find(:all, 
                       :conditions => 
                       {:category_id => c.id }
                       )
  return alltasks
end

def selectTasksMatching(regex)
  c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
  alltasks=  Task.find(:all, 
                       :conditions => 
                       {:category_id => c.id }
            ).find_all { |j| 
               j.entry =~ regex and j.completed.nil?
            }
  return alltasks
end

def connect
  ActiveSupport::Deprecation.silenced = true
  ActiveRecord::Base.establish_connection( :adapter => "sqlite3", :dbfile => DBFILE )
end

desc "Second Task"
task :writeTasks do |t|
  connect()
  entry = getYamlFile
  curFile = currentDay()
  puts "File is #{curFile}"
  if !File.directory?( curFile.pathmap("%d") )
    mkdir_p( curFile.pathmap("%d") )
  end
  fp = File.open(curFile,"w+")
  fp.write( entry )
  fp.close
  puts `cat #{curFile}`
end

def formatTasks(tasks)
  retstring = "#\n# Tasks\n#\n"
  retstring += "date: #{Date.today.strftime("%m/%d/%Y")}\n"
  retstring += "\n"
  retstring += "tasks: \n"
  tasks.each {|i|
    retstring += i.new_to_yaml("")
  }
  retstring += "\n\n"
  return retstring    
end

def getOnlyTasks
  retstring = "#\n# Tasks\n#\n"
  retstring += "date: #{Date.today.strftime("%m/%d/%Y")}\n"
  retstring += "\n"
  retstring += "tasks: \n"
  c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
  Task.find(:all, 
            :conditions => ["category_id == :id",
                             { :id    => c.id }
                           ]
           ).find_all { |j| j.parents.empty?   and 
                            ( j.completed.nil? || 
                              j.completed >= Date.today.to_time )
                       }.each { |i| 
    retstring += i.new_to_yaml("")
  }
  retstring += "\n\n"
  return retstring
end

#
#
#
def getYamlFile
  retstring = getOnlyTasks
  c = Category.find(:all, :conditions => ['name = ?',"diary"] ).first
  retstring += "\n\njournal:\n"
  getTasks("diary").find_all { |i|
    i.start >= Date.today.to_time and 
    ( i.completed.nil? || i.completed > Date.today.to_time )
  }.each { |j|
    retstring += "  - time: #{j.start}\n"
    tmp = {}
    tmp["desc"] = j.entry
    retstring += "    desc:"

    if j.entry =~ /\n/ 
##      retstring += " |\n      #{j.entry}\n"
#@      tmpstring = " |\n      #{j.entry}\n"
      tmpstring = "      #{j.entry}"
      tmpstring.gsub!(/\n/,"\n      ")
      retstring += " |\n#{tmpstring}\n"
    else
      retstring += " #{j.entry}\n"
#    retstring += tmp.to_yaml.sub(/^---/g,'')
    end
  }
  return retstring
end

end
