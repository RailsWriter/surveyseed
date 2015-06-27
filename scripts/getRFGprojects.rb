require 'digest/hmac'
require 'net/http'
require 'uri'

class String
	def hex2bin
		scan(/../).map {|x| x.to_i(16).chr}.join
	end
end

apid = "54ef65c3e4b04d0ae6f9f4a7"
secret = "8ef1fe91d92e0602648d157f981bb934"


# Get any new offerwall surveys from Federated Sample

begin
# set timer to download every 5 mins

  starttime = Time.now
  print '************************************** getRFGProjects: Time at start', starttime
  puts

  command ='{ "command" : "livealert/inventory/1" }'

  time=Time.now.to_i
  hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.hex2bin, Digest::SHA1)
  uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")

  Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
	  req = Net::HTTP::Post.new uri
	  req.body = command
	  req.content_type = 'application/json'
	  response = http.request req
    RFGProjectsIndex = JSON.parse(response.body)  
  end

  print "RFGProjectsIndex: ", RFGProjectsIndex["response"]["projects"]
  puts

  NumberOfProjects = RFGProjectsIndex["response"]["projects"].length
  
  print "************ Number of projects: ", NumberOfProjects
  puts

  (0..NumberOfProjects-1).each do |i|
    
    skipProject = false
     
    if (RfgProject.where("rfg_id = ?", RFGProjectsIndex["response"]["projects"][i]["rfg_id"])).exists? == true then
      
      RfgProject.where( "rfg_id = ?", RFGProjectsIndex["response"]["projects"][i]["rfg_id"] ).each do |existingproject|
        @project=existingproject        
        print '************ Processing an EXISTING project:', @project.rfg_id
        puts
        
        if RFGProjectsIndex["response"]["projects"][i]["lastModified"] == @project.lastModified then
          skipProject = true # no need to update if no modifications
        else
          
          @project.title = RFGProjectsIndex["response"]["projects"][i]["title"]
          @project.cpi = RFGProjectsIndex["response"]["projects"][i]["cpi"]
          @project.estimatedIR = RFGProjectsIndex["response"]["projects"][i]["estimatedIR"]
          @project.estimatedLOI = RFGProjectsIndex["response"]["projects"][i]["estimatedLOI"]
          @project.endOfField = RFGProjectsIndex["response"]["projects"][i]["endOfField"]
          @project.desiredCompletes = RFGProjectsIndex["response"]["projects"][i]["desiredCompletes"]
          @project.currentCompletes = RFGProjectsIndex["response"]["projects"][i]["currentCompletes"]
          @project.collectsPII = RFGProjectsIndex["response"]["projects"][i]["collectsPII"]
          @project.state = RFGProjectsIndex["response"]["projects"][i]["state"]
          @project.datapoints = RFGProjectsIndex["response"]["projects"][i]["datapoints"]
          @project.duplicationKey = RFGProjectsIndex["response"]["projects"][i]["duplicationKey"]
          @project.filterMode = RFGProjectsIndex["response"]["projects"][i]["filterMode"]
          @project.isRecontact = RFGProjectsIndex["response"]["projects"][i]["isRecontact"]
          @project.mobileOptimized = RFGProjectsIndex["response"]["projects"][i]["mobileOptimized"]
          @project.lastModified = RFGProjectsIndex["response"]["projects"][i]["lastModified"]
        
          
          if (RFGProjectsIndex["response"]["projects"][i]["state"] != 2) || (@project.desiredCompletes == @project.currentCompletes) then
            @project.projectStillLive = false
            skipProject = true # no need to update if no modifications
          else
            @project.projectStillLive = true
          end
          
          @project.save
        
        end # if lastModified
        
      end # do existingproject
      
    else
    
      puts '************ Processing a NEW project'
      if ((RFGProjectsIndex["response"]["projects"][i]["country"] == "CA") || (RFGProjectsIndex["response"]["projects"][i]["country"] == "US")) &&
        ( RFGProjectsIndex["response"]["projects"][i]["cpi"] > "$0.99" ) then
      
        @project = RfgProject.new
        @project.rfg_id = RFGProjectsIndex["response"]["projects"][i]["rfg_id"]
        @project.title = RFGProjectsIndex["response"]["projects"][i]["title"]
        @project.country = RFGProjectsIndex["response"]["projects"][i]["country"]
        @project.cpi = RFGProjectsIndex["response"]["projects"][i]["cpi"]
        @project.estimatedIR = RFGProjectsIndex["response"]["projects"][i]["estimatedIR"]
        @project.estimatedLOI = RFGProjectsIndex["response"]["projects"][i]["estimatedLOI"]
        @project.endOfField = RFGProjectsIndex["response"]["projects"][i]["endOfField"]
        @project.desiredCompletes = RFGProjectsIndex["response"]["projects"][i]["desiredCompletes"]
        @project.currentCompletes = RFGProjectsIndex["response"]["projects"][i]["currentCompletes"]
        @project.collectsPII = RFGProjectsIndex["response"]["projects"][i]["collectsPII"]
        @project.state = RFGProjectsIndex["response"]["projects"][i]["state"]
        @project.datapoints = RFGProjectsIndex["response"]["projects"][i]["datapoints"]
        @project.duplicationKey = RFGProjectsIndex["response"]["projects"][i]["duplicationKey"]
        @project.filterMode = RFGProjectsIndex["response"]["projects"][i]["filterMode"]
        @project.isRecontact = RFGProjectsIndex["response"]["projects"][i]["isRecontact"]
        @project.mobileOptimized = RFGProjectsIndex["response"]["projects"][i]["mobileOptimized"]  
        @project.lastModified = RFGProjectsIndex["response"]["projects"][i]["lastModified"]
      
        print "********** Saved a New project available with project.rfg_id: ", @project.rfg_id
        puts
        
        if (@project.state != 2) || (@project.desiredCompletes == @project.currentCompletes) then
          @project.projectStillLive = false
          skipProject = true # no need to update if no modifications
        else
          @project.projectStillLive = true
        end
        
        @project.save
        
      else
        puts "This NEW project does not meet our criteria, skip it"
        skipProject = true
      end # This NEW project does not meet our criteria
    
    end # project exists?
    
    print "************ skipProject =", skipProject
    puts
    
    if (skipProject == false) then
        command = { :command => "livealert/stats/1", :rfg_id => @project.rfg_id }.to_json        

        time=Time.now.to_i
        hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.hex2bin, Digest::SHA1)
        uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")

      begin
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          req = Net::HTTP::Post.new uri
          req.body = command
          req.content_type = 'application/json'
          response = http.request req
          RFGProjectStats = response.body && response.body.length >= 2 ? JSON.parse(response.body) : nil
        end
       
       rescue
#      rescue Net::ReadTimeout => e  
        puts "************** ------------>>>>>>>>>>Rescue in 155 due to {}<<<<<<<<<<<<<-----------*******"
#        false
        retry if (retries -= 1) > 0
      end

   #     print "******************* RFGProjectStats: ", RFGProjectStats
  #      puts



      if (RFGProjectStats == nil) then
        puts "*******************RFGProjectStats is NIL"
     
      else

        @project.starts = RFGProjectStats["response"]["starts"]
        @project.completes = RFGProjectStats["response"]["completes"]
        @project.terminates = RFGProjectStats["response"]["terminates"]
        @project.quotasfull = RFGProjectStats["response"]["quotas"]
        @project.cr = RFGProjectStats["response"]["cr"]
        
        if (RFGProjectStats["response"]["epc"] == "0") || (RFGProjectStats["response"]["epc"] == 0 ) then
          print "******* (if) EPC is ", RFGProjectStats["response"]["epc"]
          puts
          @project.epc = "$.00"
        else
          print "******* (else) EPC is ", RFGProjectStats["response"]["epc"]
          puts
          @project.epc = RFGProjectStats["response"]["epc"]
        end
        @project.projectCR = RFGProjectStats["response"]["projectCR"]
        @project.projectEPC = RFGProjectStats["response"]["projectEPC"]

      end
        
        if (@project.NumberofAttempts == nil) then
          @project.NumberofAttempts = 0
        else
        end
        
        if (@project.AttemptsAtLastComplete == nil) then
          @project.AttemptsAtLastComplete = 0
        else
        end
        
        @RFGAttemptsSinceLastComplete = @project.NumberofAttempts - @project.AttemptsAtLastComplete
        if @RFGAttemptsSinceLastComplete  > 15 then
          
          print "---------------------------------------->> Updating epc and ProjectEPC to lower rank for: ", @project.rfg_id
          puts
          @project.epc = "$.00"
          @project.projectEPC = "$.00"
        else
        end
        
        
  #      puts "********* saved stats"
      
      
        # Get project targeting information
      
        #command='{ "command" : "livealert/targeting/1", "rfg_id" : @project.rfg_id}'
        command = { :command => "livealert/targeting/1", :rfg_id => @project.rfg_id }.to_json
        
        time=Time.now.to_i
        hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.hex2bin, Digest::SHA1)
        uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")

      begin
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          req = Net::HTTP::Post.new uri
          req.body = command
          req.content_type = 'application/json'
          response = http.request req
          @responsecode = response.code
          print "@responsecode: ", @responsecode
          puts
          RFGProjectTargets = JSON.parse(response.body)
        end

      rescue
        puts "************** ------------>>>>>>>>>>Rescue in 237 due to {}<<<<<<<<<<<<<-----------*******"
#        false
        retry if (retries -= 1) > 0
      end
      
#        print "RFGProjectTargets: ", RFGProjectTargets
 #       puts
        
 #     if @responsecode == 200 then
        
        @project.datapoints = RFGProjectTargets["response"]["datapoints"]
        @project.lastModified = RFGProjectTargets["response"]["lastModified"]
        @project.filterMode = RFGProjectTargets["response"]["filtermode"]
        @project.quotaLimitBy = RFGProjectTargets["response"]["quotaLimitBy"]
        @project.excludeNonMatching = RFGProjectTargets["response"]["excludeNonMatching"]
        @project.quotas = RFGProjectTargets["response"]["quotas"]
      
      
        if RFGProjectTargets["response"]["desiredCompletes"] > RFGProjectTargets["response"]["currentCompletes"] then
          @project.projectStillLive = true
        else
          @project.projectStillLive = false
        end
      
      
        # CreateLink for the project
      
        command = { :command => "livealert/createLink/1", :rfg_id => @project.rfg_id }.to_json
        
        time=Time.now.to_i
        hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.hex2bin, Digest::SHA1)
        uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")


        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          req = Net::HTTP::Post.new uri
          req.body = command
          req.content_type = 'application/json'
          response = http.request req
          RFGProjectLink = JSON.parse(response.body)  
        end   
        
 #       print "********* Got Link: ", RFGProjectLink
#        puts
      
        if RFGProjectLink["result"] == 0 then
          @project.link = RFGProjectLink["response"]["link"]
          @project.projectStillLive = true
          @project.save
          print "************ Project saved: ", @project.rfg_id
          puts
        else
          @project.projectStillLive = false
          @project.save
          print "********** Project not live - RFGProjectLink: ", RFGProjectLink
          puts
        end
        
 #     else
#      puts "project targets not available, @responsecode != 200"
 #     end # @responsecode != 200
        
    else
      puts "project skipped as it does not meet biz criteria or there has been no change to the project data since last sweep"
    end # project skipped as it does not meet biz criteria or there has been no change to the project data since last sweep
  
    print "Current i: ", i
    puts
  end # do loop for all i
 
  
  # Delete projects which are neither custom entered nor on the index list but are in local database
    
  projectsnottobedeleted = Array.new
  listofprojectnumbers = Array.new
  projectstobedeleted = Array.new
    
  RfgProject.all.each do |oldproject|
    listofprojectnumbers << oldproject.rfg_id
    # print '************* Investigating Project Number from the dbase: ', listofprojectnumbers
    # puts
      
    (0..NumberOfProjects-1).each do |k|
      if RFGProjectsIndex["response"]["projects"][k]["rfg_id"] == oldproject.rfg_id then
          #          print 'Marked a project to be ALIVE: ', oldproject.rfg_id
          #          puts     
        projectsnottobedeleted << oldproject.rfg_id
      else
        # do nothing
      end # if
        #         print 'looping list of allocationsurveys, count:', k
        #         puts
    end # do k
  end # do oldproject
     
  # print '******************** List of all projects in DB', listofprojectnumbers
  # puts
  # print '****************** List of projects not to be deleted', projectsnottobedeleted
  # puts

  #   This section is there to remove old dead projects.
    
  RfgProject.all.each do |oldproject| #do21
    if projectsnottobedeleted.include? (oldproject.rfg_id) then
         # do nothing
    else
      projectstobedeleted << oldproject.rfg_id
      print '******************** DELETING THIS Project NUMBER NOT on Index LIST: ', oldproject.rfg_id
      puts
      oldproject.delete
    end
  end # do21 oldproject
    
  print 'Projects deleted: ', projectstobedeleted
  puts
  
 
  timenow = Time.now
  
  print 'getRFGProjects: Time at end', timenow
  puts
  
  if (timenow - starttime) > 60 then 
    print 'time elapsed since start =', (timenow - starttime), '- going to repeat immediately'
    puts
    timetorepeat = true
  else
    print 'time elapsed since start =', (timenow - starttime), '- going to sleep for 1 minutes'
    puts
    sleep (1.minutes)
    timetorepeat = true
  end

end while timetorepeat