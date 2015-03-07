class RemoveChildrenColumnsFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :children, :string
  end
end
