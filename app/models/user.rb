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
		  csv << %w{ UTC ID }
			User.where('netid =? AND updated_at >= ?', "Na34dAasIY09muLqxd59A", Date.today.last_month.beginning_of_month).order("updated_at").each do |c|
			# User.where('netid =? AND updated_at BETWEEN ? AND ?', "Na34dAasIY09muLqxd59A", Date.today.last_month.beginning_of_month, Date.today.last_month.end_of_month).order("updated_at").each do |c|
			# User.where('netid =? AND updated_at > ?', "Na34dAasIY09muLqxd59A", (Time.now - 45.days)).order("updated_at").each do |c|
			# if c.SurveysCompleted.flatten(2).length > 0 then
				if c.SurveysCompleted.count > 0 then
					(0..c.SurveysCompleted.count-1).each do |i|
						print "**********DateCompleted**************************", c.SurveysCompleted.flatten(2).at(-7-7*i).to_date
						puts
						if (c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon <= Date.today.last_month.beginning_of_month.mon) && (c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon >= Date.today.last_month.end_of_month.mon) then
						# if (c.SurveysCompleted.flatten(2).at(-7-7*i).to_s[5..6].to_i <= Date.today.last_month.beginning_of_month.mon.to_s.to_i) && (c.SurveysCompleted.flatten(2).at(-7-7*i).to_s[5..6].to_i >= Date.today.last_month.end_of_month.mon.to_s.to_i) then
							print "**********MonthCompleted**************************", c.SurveysCompleted.flatten(2).at(-7-7*i).to_date.mon
							puts
							csv << [c.SurveysCompleted.flatten(2).at(-7-7*i), c.SurveysCompleted.flatten(2).at(-2-7*i).to_s]
						else
						end
					end
				else
				end
			end
 		end
	end

end