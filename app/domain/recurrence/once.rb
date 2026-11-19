module Recurrence
  # Une seule échéance, le jour due_on (au début du jour local). Une fois faite, il n'y en a plus.
  class Once
    attr_reader :due_on

    def initialize(due_on:)
      raise InvalidConfig, "due_on must be a Date, got #{due_on.inspect}" unless due_on.is_a?(Date)

      @due_on = due_on
    end

    def next_due_at(last_completed_at:)
      due_on.in_time_zone if last_completed_at.nil?
    end
  end
end
