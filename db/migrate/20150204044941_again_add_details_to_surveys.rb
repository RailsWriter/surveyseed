class AgainAddDetailsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :KEPC, :float
    add_column :surveys, :GEPC, :float
    add_column :surveys, :FailureCount, :integer
    add_column :surveys, :OverQuotaCount, :integer    
  end
end
