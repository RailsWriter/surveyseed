class AddNetIdClickIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :netid, :string
    add_column :users, :clickid, :string
  end
end
