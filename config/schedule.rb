# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# set :output, "log/cron_log.log"
set :output, "/tmp/cron_log.log" # todo: figure out how to write tp log/ folder instead
env :PATH, ENV['PATH']

# every :day, :at => '8:00pm' do
# 	rake "sendEmailDaily:email_sender", :environment => "development"
# end

# every :day, :at => '3:22am' do
#     rake "sendEmailDaily:email_sender", :environment => "production"
# end

# every :monday, :at => '12:00am' do
#     rake "sendEmailOnAlternateDays:email_sender", :environment => "development"
# end

# every :monday, :at => '11:00pm' do
#     rake "sendEmailOnAlternateDays:email_sender", :environment => "production"
# end

# every :wednesday, :at => '12:00am' do
#     rake "sendEmailOnAlternateDays:email_sender", :environment => "development"
# end

# every :wednesday, :at => '11:00pm' do
#     rake "sendEmailOnAlternateDays:email_sender", :environment => "production"
# end

# every :friday, :at => '12:00am' do
#     rake "sendEmailOnAlternateDays:email_sender", :environment => "development"
# end

# every :friday, :at => '11:00pm' do
#     rake "sendEmailOnAlternateDays:email_sender", :environment => "production"
# end

# every :saturday, :at => '12:00am' do
#     rake "sendEmailWeekly:email_sender", :environment => "development"
# end

# every :saturday, :at => '11:00pm' do
#     rake "sendEmailWeekly:email_sender", :environment => "production"
# end

# every 5.minute do
#     rake "testRake:test1"
# end
