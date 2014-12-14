class CreateNetworks < ActiveRecord::Migration
  def change
    create_table :networks do |t|
      t.string :name
      t.string :netid
      t.float :payout
      t.string :status
      t.text :testcompletes, :limit => 5000000
      t.text :completes, :limit => 50000000

      t.timestamps null: false
    end
  end
end
