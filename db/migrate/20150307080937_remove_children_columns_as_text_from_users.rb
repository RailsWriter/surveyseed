class RemoveChildrenColumnsAsTextFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :children, :text
  end
end
