class RemoveGeosColumn < ActiveRecord::Migration
  def change
    remove_column :us_geos, :unacceptable_cities, :string
  end
end
