# What the household maintains and the app reminds of (ADR 0016): a pool, a dishwasher, a water heater… Generic: a
# kind from the catalogue (config/catalogue.yml, "other" for one of its own), a name and the notes "À savoir". Its
# tasks and photos hang on it as their subject.
class CreateEquipment < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment do |t|
      t.references :household, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :name, null: false
      t.text :notes
      t.timestamps
    end
  end
end
