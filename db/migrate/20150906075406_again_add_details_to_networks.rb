class AgainAddDetailsToNetworks < ActiveRecord::Migration
  def change
    add_column :networks, :RFG_AU, :integer
  end
end
