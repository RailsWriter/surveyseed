class UpdateColumnsInUser < ActiveRecord::Migration
  def change
  	add_column :users, :Pii1, :text
  	add_column :users, :Pii2, :text
  	add_column :users, :Pii3, :text
  	add_column :users, :Pii4, :text
  	add_column :users, :Pii5, :text
  end
end
