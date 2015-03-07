class AddNewChildrenColumnsAgainToUsers < ActiveRecord::Migration
  def change
    add_column :users, :children, :string
  end
end
