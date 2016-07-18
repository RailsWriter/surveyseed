class UpdateMoreColumnInAdhoc < ActiveRecord::Migration
  def change
  	change_column :adhocs, :SupplierLink, :string
  end
end
