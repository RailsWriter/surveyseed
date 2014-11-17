class RemoveAttemptsTimeStampsArrayFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :attempts_time_stamps_array, :array
  end
end
