class ChangeSurveyQuotaColumn < ActiveRecord::Migration
  def change
    change_column :surveys, :SurveyQuotas, :text, :limit => 50000000
  end
end
