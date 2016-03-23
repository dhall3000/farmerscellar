class CreateNightlyTaskRuns < ActiveRecord::Migration
  def change
    create_table :nightly_task_runs do |t|

      t.timestamps null: false
    end
  end
end
