class AddAttemptsTimeStampsArrayFromUsers < ActiveRecord::Migration
  def change
    add_column :users, :attempts_time_stamps_array, :text
  end
end
