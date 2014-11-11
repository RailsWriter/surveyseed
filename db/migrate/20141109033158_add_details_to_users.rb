class AddDetailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :session_id, :string
    add_column :users, :ip_address, :string
    add_column :users, :user_agent, :string
  end
end
