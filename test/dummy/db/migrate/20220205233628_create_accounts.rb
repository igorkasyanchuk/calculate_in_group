class CreateAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :accounts do |t|
      t.string :name

      t.timestamps
    end

    add_column :users, :account_id, :integer
  end
end
