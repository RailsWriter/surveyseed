class CreateUsGeos < ActiveRecord::Migration
  def change
    create_table :us_geos do |t|
      t.string :zip
      t.string :zip_type
      t.string :primary_city
      t.string :acceptable_cities
      t.string :unacceptable_cities
      t.string :county
      t.string :timezone
      t.string :area_codes
      t.float :latitude
      t.float :longitude
      t.string :world_region
      t.string :country
      t.boolean :decommissioned
      t.integer :estimated_population
      t.string :notes
      t.string :City
      t.string :CriteriaID
      t.string :State
      t.string :StateAbrv
      t.string :DMARegion
      t.string :DMARegionCode

      t.timestamps null: false
    end
  end
end
