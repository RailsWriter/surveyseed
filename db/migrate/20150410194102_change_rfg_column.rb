class ChangeRfgColumn < ActiveRecord::Migration
  def change
    change_column :rfg_projects, :datapoints, :text, :limit => 1000000
  end
end
