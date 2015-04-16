class AddDetailsToRfgProject < ActiveRecord::Migration
  def change
    add_column :rfg_projects, :NumberofAttempts, :integer
    add_column :rfg_projects, :AttemptsAtLastComplete, :integer
  end
end
