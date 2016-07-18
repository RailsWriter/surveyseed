class UpdateAgainColumnInAdhoc < ActiveRecord::Migration
  def change
  	change_column :adhocs, :SurveyQuotas, :text, :limit => 5000000
  end
end
