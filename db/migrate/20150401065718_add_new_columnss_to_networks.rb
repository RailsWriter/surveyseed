class AddNewColumnssToNetworks < ActiveRecord::Migration
  def change
    add_column :networks, :FED_US, :integer
    add_column :networks, :FED_CA, :integer
    add_column :networks, :FED_AU, :integer
    add_column :networks, :RFG_US, :integer
    add_column :networks, :RFG_CA, :integer
    add_column :networks, :stackOrder, :string
  end
end
