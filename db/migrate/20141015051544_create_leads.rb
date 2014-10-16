class CreateLeads < ActiveRecord::Migration
  def change
    create_table :leads do |t|
      t.string :name
      t.string :email
      t.string :message

      t.timestamps null: false
    end
  end
end
