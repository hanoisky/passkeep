class CreateTeamProjects < ActiveRecord::Migration
  def change
    create_table :team_projects do |t|
      t.references :project
      t.references :team

      t.timestamps
    end
    add_index :team_projects, :project_id
    add_index :team_projects, :team_id
  end
end
