module FablabConfiguration
	def fablab_plans_deactivated?
		Rails.application.secrets.fablab_without_plans
	end
end
