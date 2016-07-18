class AddColumnToAdhoc < ActiveRecord::Migration
  def change
    add_column :adhocs, :CompletedBy, :text
  end
end
