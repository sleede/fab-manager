class AddStepNbToProjectStep < ActiveRecord::Migration
  def up
    add_column :project_steps, :step_nb, :integer
    execute 'UPDATE project_steps
             SET step_nb = subquery.index
             FROM (
                SELECT
                  id, project_id, created_at,
                  row_number() OVER (PARTITION BY project_id) AS index
                FROM project_steps
                ORDER BY created_at
             ) AS subquery
             WHERE project_steps.id = subquery.id;'
  end

  def down
    remove_column :project_steps, :step_nb
  end
end
