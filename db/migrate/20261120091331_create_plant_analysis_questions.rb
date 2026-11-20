class CreatePlantAnalysisQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :plant_analysis_questions do |t|
      t.references :plant_analysis, null: false, foreign_key: true, index: false
      t.references :asked_by, foreign_key: { to_table: :users }
      # The photo attached to the question is also one of the plant's photos: deleting it keeps the question.
      t.references :photo, foreign_key: { on_delete: :nullify }
      t.text :body, null: false
      t.string :status, null: false, default: "pending"
      t.text :answer
      t.string :error
      t.string :model
      t.datetime :finished_at

      t.timestamps
    end

    add_index :plant_analysis_questions, [ :plant_analysis_id, :created_at ]
    # One question at a time per analysis: the next one waits for the answer.
    add_index(
      :plant_analysis_questions,
      :plant_analysis_id,
      unique: true,
      where: "status = 'pending'",
      name: "index_plant_analysis_questions_one_pending"
    )
  end
end
