module FablabConfiguration
	def fablab_plans_deactivated?
		Rails.application.secrets.fablab_without_plans
	end

	def fablab_spaces_deactivated?
		Rails.application.secrets.fablab_without_spaces
	end
end
