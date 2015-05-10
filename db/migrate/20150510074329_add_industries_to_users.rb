class AddIndustriesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :industries, :text
  end
end
