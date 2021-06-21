# frozen_string_literal: true

json.extract! pack, :id, :priceable_id, :priceable_type, :group_id, :validity_interval, :validity_count, :minutes
json.amount pack.amount / 100.0
json.usages pack.statistic_profile_prepaid_packs.count
