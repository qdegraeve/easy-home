# "Après la dernière fois" counts in days, weeks, months or years (docs/conception/equipements-et-taches.md): the
# config of a sliding task goes from { "interval_days" => 3 } to { "interval" => 3, "unit" => "days" }, its start
# date kept. Reversible while every rule is still in days.
class MoveSlidingIntervalToUnit < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE tasks
      SET recurrence_config = (recurrence_config - 'interval_days')
        || jsonb_build_object('interval', recurrence_config -> 'interval_days', 'unit', 'days')
      WHERE recurrence_type = 'sliding' AND recurrence_config ? 'interval_days'
    SQL
  end

  def down
    if select_value("SELECT 1 FROM tasks WHERE recurrence_type = 'sliding' AND recurrence_config ->> 'unit' <> 'days'")
      raise ActiveRecord::IrreversibleMigration, "Some sliding tasks count in weeks, months or years"
    end

    execute <<~SQL.squish
      UPDATE tasks
      SET recurrence_config = (recurrence_config - 'interval' - 'unit')
        || jsonb_build_object('interval_days', recurrence_config -> 'interval')
      WHERE recurrence_type = 'sliding' AND recurrence_config ? 'interval'
    SQL
  end
end
