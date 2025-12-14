class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: 'pending'
      t.date :due_date
      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :tasks, :status
    add_index :tasks, :due_date, where: 'due_date IS NOT NULL'
  end
end
