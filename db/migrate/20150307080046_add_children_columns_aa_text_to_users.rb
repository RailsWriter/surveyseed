class AddChildrenColumnsAaTextToUsers < ActiveRecord::Migration
  def change
    add_column :users, :children, :text
  end
end
