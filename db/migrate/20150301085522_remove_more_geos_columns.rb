class RemoveMoreGeosColumns < ActiveRecord::Migration
  def change
    remove_column :us_geos, :acceptable_cities, :string
    remove_column :us_geos, :notes, :string
  end
end
