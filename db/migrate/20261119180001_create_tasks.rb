class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :household, null: false, foreign_key: true
      t.references :subject, polymorphic: true
      t.string :title, null: false
      t.string :template_key
      t.string :recurrence_type, null: false
      t.jsonb :recurrence_config, null: false, default: {}
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
