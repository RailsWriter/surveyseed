class AddNewQualColumnsToNetworks < ActiveRecord::Migration
  def change
    add_column :networks, :P2S_US, :integer
    add_column :networks, :P2S_CA, :integer
    add_column :networks, :P2S_AU, :integer
  end
end
