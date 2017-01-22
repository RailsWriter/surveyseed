class AddColumnsToUser < ActiveRecord::Migration
  def change
    add_column :users, :emailId, :string
    add_column :users, :password, :string
    add_column :users, :acceptTermsVersion, :string
    add_column :users, :acceptedTerms, :string, :default => 'f'
    add_column :users, :dateTermsAccepted, :datetime
    add_column :users, :userType, :string
    add_column :users, :redeemRewards, :string, :default => '1'
    add_column :users, :surveyFrequency, :string, :default => '1'
  end
end
