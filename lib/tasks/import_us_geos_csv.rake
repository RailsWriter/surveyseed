require 'csv'
namespace :import_us_geos_csv do
  task :create_us_geos => :environment do
    csv_text = File.read("lib/assets/us_geos.csv")
    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |row|
      UsGeo.create!(row.to_hash)
    end
  end
end 