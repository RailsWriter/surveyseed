class AddMoreDetailsToRfgProject < ActiveRecord::Migration
  def change
    add_column :rfg_projects, :CompletedBy, :text
  end
end
