class User < ActiveRecord::Base    
  	serialize :attempts_time_stamps_array, Array
  	serialize :QualifiedSurveys, Array
  	serialize :SurveysWithMatchingQuota, Array
  	serialize :SupplierLink, Array
  	serialize :SurveysAttempted, Array
  	serialize :SurveysCompleted, Hash
  	serialize :children, Array
  	serialize :industries, Array

  	def self.to_csv
	  	CSV.generate do |csv|
		  csv << %w{ UTC ID (Please-ignore-16994*-and-any-other-non-standard-IDs)}
		  # csv << %w{second line}
			User.where('netid =? AND updated_at >= ?', "Na34dAasIY09muLqxd59A", Date.today.beginning_of_month).order("updated_at").each do |c|
			# User.where('netid =? AND updated_at >= ?', "Na34dAasIY09muLqxd59A", Date.today.last_month.beginning_of_month).order("updated_at").each do |c|
			# User.where('netid =? AND updated_at BETWEEN ? AND ?', "Na34dAasIY09muLqxd59A", Date.today.last_month.beginning_of_month, Date.today.last_month.end_of_month).order("updated_at").each do |c|
			# User.where('netid =? AND updated_at > ?', "Na34dAasIY09muLqxd59A", (Time.now - 45.days)).order("updated_at").each do |c|
			# if c.SurveysCompleted.flatten(2).length > 0 then
				if c.SurveysCompleted.count > 0 then
					print "**********Found Completes in user id ************************** = ", c.id
					puts
					if c.SurveysCompleted.flatten(2).include?("TESTSURVEY") then
						print "******** Skip this record because it is a TESTSURVEY **********"
					else
						@SurveysCompletedArray = c.SurveysCompleted.flatten(2)
						if (@SurveysCompletedArray[0].is_a?String) then
          					# ignore - it is older storage format
        				else
							(0..c.SurveysCompleted.count-1).each do |i|
								print "**********DateCompleted**************************", c.SurveysCompleted.flatten(2).at(-7-7*i).to_date
								puts
								if (c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon >= Date.today.beginning_of_month.mon) && (c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon <= Date.today.end_of_month.mon) then
								# if (c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon >= Date.today.last_month.beginning_of_month.mon) && (c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon <= Date.today.last_month.end_of_month.mon) then
									print "**********MonthCompleted**************************", c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon
									puts
									csv << [c.SurveysCompleted.flatten(2).at(-7-7*i), "\"#{c.SurveysCompleted.flatten(2).at(-2-7*i)}\""]
								else
								end
							end
						end
					end
				else
				end
			end
 		end
	end


	def self.to_lmcsv
	  	CSV.generate do |csv|
		  csv << %w{ UTC ID (Please-ignore-16994*-and-any-other-non-standard-IDs)}
			# User.where('netid =? AND updated_at >= ?', "Na34dAasIY09muLqxd59A", Date.today.beginning_of_month).order("updated_at").each do |c|
			User.where('netid =? AND updated_at >= ?', "Na34dAasIY09muLqxd59A", Date.today.last_month.beginning_of_month).order("updated_at").each do |c|
			# User.where('netid =? AND updated_at BETWEEN ? AND ?', "Na34dAasIY09muLqxd59A", Date.today.last_month.beginning_of_month, Date.today.last_month.end_of_month).order("updated_at").each do |c|
			# User.where('netid =? AND updated_at > ?', "Na34dAasIY09muLqxd59A", (Time.now - 45.days)).order("updated_at").each do |c|
			# if c.SurveysCompleted.flatten(2).length > 0 then
				if c.SurveysCompleted.count > 0 then
					print "**********Found Completes in user id ************************** = ", c.id
					puts
					if c.SurveysCompleted.flatten(2).include?("TESTSURVEY") then
						print "******** Skip this record because it is a TESTSURVEY **********"
					else
						@SurveysCompletedArray = c.SurveysCompleted.flatten(2)
						if (@SurveysCompletedArray[0].is_a?String) then
          					# ignore - it is older storage format
        				else
							(0..c.SurveysCompleted.count-1).each do |i|
								print "**********DateCompleted**************************", c.SurveysCompleted.flatten(2).at(-7-7*i).to_date
								puts
								# if (c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon >= Date.today.beginning_of_month.mon) && (c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon <= Date.today.end_of_month.mon) then
								if (c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon >= Date.today.last_month.beginning_of_month.mon) && (c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon <= Date.today.last_month.end_of_month.mon) then
									print "**********MonthCompleted**************************", c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon
									puts
									csv << [c.SurveysCompleted.flatten(2).at(-7-7*i), "\"#{c.SurveysCompleted.flatten(2).at(-2-7*i)}\""]
								else
								end
							end
						end
					end
				else
				end
			end
 		end
	end
end