class CreateRfgProjects < ActiveRecord::Migration
  def change
    create_table :rfg_projects do |t|
      t.string :rfg_id
      t.string :title
      t.string :country
      t.string :cpi
      t.integer :estimatedIR
      t.integer :estimatedLOI
      t.datetime :endOfField
      t.integer :desiredCompletes
      t.integer :currentCompletes
      t.boolean :collectsPII
      t.integer :state
      t.text :datapoints
      t.datetime :lastModified
      t.string :duplicationKey
      t.integer :filterMode
      t.boolean :isRecontact
      t.string :mobileOptimized

      t.timestamps null: false
    end
  end
end
