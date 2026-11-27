# Deleting an account (ADR 0019) keeps what the person did: the journal says "un ancien membre", an analysis or a
# question stays without its author.
class NullifyUserReferencesOnDelete < ActiveRecord::Migration[8.1]
  REFERENCES = [
    [ :task_occurrences, :completed_by_id ],
    [ :plant_analyses, :requested_by_id ],
    [ :plant_analysis_questions, :asked_by_id ]
  ].freeze

  def up
    REFERENCES.each do |table, column|
      remove_foreign_key table, :users, column: column
      add_foreign_key table, :users, column: column, on_delete: :nullify
    end
  end

  def down
    REFERENCES.each do |table, column|
      remove_foreign_key table, :users, column: column
      add_foreign_key table, :users, column: column
    end
  end
end
