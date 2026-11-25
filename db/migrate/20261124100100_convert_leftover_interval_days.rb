# Second step of MoveSlidingIntervalToUnit: a sliding task written in the former format ({ "interval_days" => 3 })
# by the code before it, while it was deployed or after a rollback, is converted again, now that Recurrence.build no
# longer reads that format. Idempotent; nothing to undo (the former code read both formats once migrated).
class ConvertLeftoverIntervalDays < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE tasks
      SET recurrence_config = (recurrence_config - 'interval_days')
        || jsonb_build_object('interval', recurrence_config -> 'interval_days', 'unit', 'days')
      WHERE recurrence_type = 'sliding' AND recurrence_config ? 'interval_days'
    SQL
  end

  def down
    # Nothing to do: the converted tasks stay valid for the previous code.
  end
end
