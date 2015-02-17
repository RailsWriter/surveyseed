class FurtherAddDetailsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :label, :string
  end
end
