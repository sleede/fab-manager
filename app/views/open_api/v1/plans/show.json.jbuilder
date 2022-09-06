# frozen_string_literal: true

json.partial! 'open_api/v1/plans/plan', plan: @plan
json.extract! @plan, :training_credit_nb, :is_rolling, :description, :type, :plan_category_id
json.file URI.join(root_url, @plan.plan_file.attachment.url) if @plan.plan_file
