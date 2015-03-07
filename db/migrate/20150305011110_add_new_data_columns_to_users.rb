class AddNewDataColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :jobtitle, :string
  end
end
