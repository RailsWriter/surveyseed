class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :birth_month
      t.integer :birth_year
      t.boolean :tos

      t.timestamps null: false
    end
  end
end
