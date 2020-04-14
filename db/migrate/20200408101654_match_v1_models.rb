# frozen_string_literal: true

# From this migration the data model will be retro-compatible with FabManager v1.x
# This will allow easier upgrades
class MatchV1Models < ActiveRecord::Migration[5.2]
  def up
    # migrate data from columns of type "varchar" to type "inet"
    add_column :users, :current_sign_in_ip_tmp, :inet
    add_column :users, :last_sign_in_ip_tmp, :inet
    User.reset_column_information
    User.all.each do |user|
      user.current_sign_in_ip_tmp = user.current_sign_in_ip
      user.last_sign_in_ip_tmp = user.last_sign_in_ip
      user.save
    end
    remove_column :users, :current_sign_in_ip, :string
    remove_column :users, :last_sign_in_ip, :string
    rename_column :users, :current_sign_in_ip_tmp, :current_sign_in_ip
    rename_column :users, :last_sign_in_ip_tmp, :last_sign_in_ip
    # add various foreign keys
    add_foreign_key :projects_machines, :projects
    add_foreign_key :projects_machines, :machines
    add_foreign_key :project_users, :projects
    add_foreign_key :project_users, :users
    add_foreign_key :project_steps, :projects
    add_foreign_key :projects_components, :projects
    add_foreign_key :projects_components, :components
    add_foreign_key :projects_themes, :projects
    add_foreign_key :projects_themes, :themes
  end

  def down
    # migrate data from columns of type "inet" to type "varchar"
    add_column :users, :current_sign_in_ip_tmp, :string
    add_column :users, :last_sign_in_ip_tmp, :string
    User.reset_column_information
    User.all.each do |user|
      user.current_sign_in_ip_tmp = user.current_sign_in_ip
      user.last_sign_in_ip_tmp = user.last_sign_in_ip
      user.save
    end
    remove_column :users, :current_sign_in_ip, :inet
    remove_column :users, :last_sign_in_ip, :inet
    rename_column :users, :current_sign_in_ip_tmp, :current_sign_in_ip
    rename_column :users, :last_sign_in_ip_tmp, :last_sign_in_ip
    # remove the foreign keys
    remove_foreign_key :projects_machines, :projects
    remove_foreign_key :projects_machines, :machines
    remove_foreign_key :project_users, :projects
    remove_foreign_key :project_users, :users
    remove_foreign_key :project_steps, :projects
    remove_foreign_key :projects_components, :projects
    remove_foreign_key :projects_components, :components
    remove_foreign_key :projects_themes, :projects
    remove_foreign_key :projects_themes, :themes
  end
end
