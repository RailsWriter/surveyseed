class UpdateColumnInSurvey < ActiveRecord::Migration
  def change
  	change_column :surveys, :CompletedBy, :text, :limit => 1000000
  end
end