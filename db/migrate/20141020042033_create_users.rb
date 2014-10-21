class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :birth_month
      t.integer :birth_year
      t.boolean :tos
      t.string :gender
      t.string :country
      t.string :ZIP
      t.string :ethnicity
      t.string :race
      t.string :eduation
      t.integer :householdcomp
      t.string :householdincome

      t.timestamps null: false
    end
  end
end
