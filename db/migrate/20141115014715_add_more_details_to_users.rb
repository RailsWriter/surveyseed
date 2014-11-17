class AddMoreDetailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :trap_question_1_response, :string
    add_column :users, :trap_question_2a_response, :string
    add_column :users, :trap_question_2b_response, :string
    add_column :users, :attempts_time_stamps_array, :text
    add_column :users, :watch_listed, :boolean
    add_column :users, :black_listed, :boolean
    add_column :users, :user_id, :string
    add_column :users, :number_of_attempts_in_last_24hrs, :integer
  end
end
