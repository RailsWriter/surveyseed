class AddMoreDetailsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :CompletedBy, :text
  end
end
