class AddFpDetailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :fingerprint, :integer, :limit => 8
  end
end
