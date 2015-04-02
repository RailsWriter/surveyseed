class AddColumnsToRfgProjects < ActiveRecord::Migration
  def change
    add_column :rfg_projects, :starts, :integer
    add_column :rfg_projects, :completes, :integer
    add_column :rfg_projects, :terminates, :integer
    add_column :rfg_projects, :quotasfull, :integer
    add_column :rfg_projects, :cr, :integer
    add_column :rfg_projects, :epc, :string
    add_column :rfg_projects, :projectCR, :integer
    add_column :rfg_projects, :projectEPC, :string
    add_column :rfg_projects, :quotaLimitBy, :string
    add_column :rfg_projects, :excludeNonMatching, :boolean
    add_column :rfg_projects, :quotas, :text
    add_column :rfg_projects, :link, :string
    add_column :rfg_projects, :projectStillLive, :boolean
  end
end
