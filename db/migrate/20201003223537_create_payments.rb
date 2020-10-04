class CreatePayments < ActiveRecord::Migration[6.0]
  def change
    create_table :payments do |t|
      t.integer :status
      t.integer :value, default: 0, null: false
      t.string :token
      t.string :purchase_details_url, default: ''
      t.string :payment_url, default: ''
      t.string :description, null: false
      t.string :code
      t.timestamps
    end
  end
end
