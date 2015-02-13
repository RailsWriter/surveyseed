class EvenAgainAddDetailsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :NumberofAttemptsAtLastComplete, :integer
    add_column :surveys, :TCR, :float
  end
end
