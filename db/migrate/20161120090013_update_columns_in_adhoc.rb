class UpdateColumnsInAdhoc < ActiveRecord::Migration
  def change
  	add_column :adhocs, :Screener1, :text
  	add_column :adhocs, :Screener2, :text
  	add_column :adhocs, :Screener3, :text
  	add_column :adhocs, :Screener4, :text
  	add_column :adhocs, :Screener5, :text
	add_column :adhocs, :Screener1Resp, :string
	add_column :adhocs, :Screener2Resp, :string
	add_column :adhocs, :Screener3Resp, :string
	add_column :adhocs, :Screener4Resp, :string
	add_column :adhocs, :Screener5Resp, :string
  	add_column :adhocs, :Pii1, :text
  	add_column :adhocs, :Pii2, :text
  	add_column :adhocs, :Pii3, :text
  	add_column :adhocs, :Pii4, :text
  	add_column :adhocs, :Pii5, :text
  end
end