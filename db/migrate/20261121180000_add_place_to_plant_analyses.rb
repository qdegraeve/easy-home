# Where the plant was when it was analysed (exposure, shelter): a later change of place makes the advice doubtful.
# Null for the analyses made before: their place is unknown, nothing is signalled for them.
class AddPlaceToPlantAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :plant_analyses, :place, :jsonb
  end
end
