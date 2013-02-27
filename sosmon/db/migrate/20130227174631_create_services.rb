class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.string :name, :null => false
      t.string :portfolio
      t.string :tags
      t.references :client, :null => false
      t.text :desc

      t.timestamps
    end
    add_index :services, :client_id
  end
end
