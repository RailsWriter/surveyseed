class FurtherAddDetailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :pindustry, :string
    add_column :users, :employment, :string
  end
end
