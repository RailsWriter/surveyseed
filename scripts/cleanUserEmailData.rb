# This script removes duplicate emails in Production environment.

begin
  timetorepeat = true
  
  print "******** cleanUserEmailData Script Starting at #{Time.now} ************"
  puts
  puts "**************************************************"
  print "Setting, if any, invalid email addresses to NIL "
  puts
  puts "**************************************************"
  puts

  # Start by validating all email addresses or set them to nil
  User.where.not(emailId: [nil, ""]).each do |c|
    if EmailValidator.valid?(c.emailId) then
      # do nothing
    else
      print "********** Setting emailId ", c.emailId, " to nil for user record_id ", c.id, " ************"
      puts
      c.emailId=nil
      c.save
    end
  end


  # Collect ids of all users with nil or empty emailId fields
  # n = User.count
  # noEmail_ids_1 = User.where(emailId: [nil, ""]).first(n/2).collect(&:id)
  # noEmail_ids_2 = User.where(emailId: [nil, ""]).last(n/2).collect(&:id)
  # duplicateEmail_ids = User.select("MIN(id) as id").group(:emailId).collect(&:id)
  # unique_ids = (noEmail_ids_1 + noEmail_ids_2 + duplicateEmail_ids).uniq


  n = User.count
  noEmail_ids_1 = User.where(emailId: [nil, ""]).first(n/2).map(&:id)
  puts "**************************************************"
  print "noEmail_ids_1: ", noEmail_ids_1
  puts
  puts
  noEmail_ids_2 = User.where(emailId: [nil, ""]).last(n/2).map(&:id)
  puts "**************************************************"
  print "noEmail_ids_2: ", noEmail_ids_2
  puts
  puts
  duplicateEmail_ids = User.select("MIN(id) as id").group(:emailId).collect(&:id)
  puts "**************** all emailids that could be duplicate **********************************"
  print "duplicateEmail_ids: ", duplicateEmail_ids
  puts
  puts
  unique_ids = (noEmail_ids_1 + noEmail_ids_2 + duplicateEmail_ids).uniq

  puts "**************************************************"
  print "Duplicate email addresses count = ", User.where.not(id: unique_ids).count
  puts
  puts "**************************************************"
  puts

  print "******** unique_ids and blanks: ", unique_ids
  puts
  puts

  puts "**************************************************"
  print "Unique_ids count: ", unique_ids.count
  puts
  puts "**************************************************"  
  puts

  # Now convert all duplicate emails into empty strings
  User.where.not(id: unique_ids).each do |r|
    puts "**************************************************"
    print "Setting duplicate emailId ", r.emailId, " to nil for user id ", r.id, " *************"
    puts
    puts "**************************************************"  
    puts
    r.emailId=nil
    r.save
  end

  print "UTC time ", Time.now
  puts	
  # print "Local time ", Time.now-7*60*60 # Mar-Nov DST
  print "Local time ", Time.now-8*60*60 # Nov - Mar PST	
  puts
  puts "cleanUserEmailData script Going to sleep for 7 days"
  sleep (168.hours)
end while timetorepeat