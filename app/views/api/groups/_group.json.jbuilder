# frozen_string_literal: true

json.extract! group, :id, :slug, :name, :disabled
json.users group.users.count
