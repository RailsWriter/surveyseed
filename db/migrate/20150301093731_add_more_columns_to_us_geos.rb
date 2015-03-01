class AddMoreColumnsToUsGeos < ActiveRecord::Migration
  def change
    add_column :us_geos, :region, :string
    add_column :us_geos, :regionPrecode, :string
    add_column :us_geos, :division, :string
    add_column :us_geos, :divisionPrecode, :string
  end
end
