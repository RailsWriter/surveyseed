class AgainAddDetailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :age, :string
    add_column :users, :SupplierLink, :text
    add_column :users, :QualifiedSurveys, :text
    add_column :users, :SurveysWithMatchingQuota, :text
  end
end
