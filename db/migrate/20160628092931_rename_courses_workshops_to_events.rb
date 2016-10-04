class RenameCoursesWorkshopsToEvents < ActiveRecord::Migration
  def up
    execute "UPDATE statistic_indices
             SET label='Évènements'
             WHERE es_type_key='event';"
  end

  def down
    execute "UPDATE statistic_indices
             SET label='Ateliers/Stages'
             WHERE es_type_key='event';"
  end
end
