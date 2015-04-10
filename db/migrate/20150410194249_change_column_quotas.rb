class ChangeColumnQuotas < ActiveRecord::Migration
  def change
    change_column :rfg_projects, :quotas, :text, :limit => 1000000
  end
end
