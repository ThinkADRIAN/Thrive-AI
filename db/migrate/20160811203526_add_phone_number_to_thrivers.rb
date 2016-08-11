class AddPhoneNumberToThrivers < ActiveRecord::Migration
  def change
    add_column :thrivers, :phone_number, :string
    add_column :thrivers, :phone_pin, :string
    add_column :thrivers, :phone_verified, :boolean
  end
end
