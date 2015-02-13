class AddDetailsToNetworks < ActiveRecord::Migration
  def change
    add_column :networks, :Flag1, :string
    add_column :networks, :Flag2, :string
    add_column :networks, :Flag3, :string
    add_column :networks, :Flag4, :string
    add_column :networks, :Flag5, :string
  end
end
