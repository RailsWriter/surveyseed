class UpdateColumnInAdhoc < ActiveRecord::Migration
  def change
  	change_column :adhocs, :QualificationZIPPreCodes, :text, :limit => 1000000
  end
end
