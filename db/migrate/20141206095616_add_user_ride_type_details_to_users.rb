class AddUserRideTypeDetailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :birth_date, :integer
    add_column :users, :currentpayout, :float
    add_column :users, :SurveysAttempted, :text
    add_column :users, :SurveysCompleted, :text
  end
end
