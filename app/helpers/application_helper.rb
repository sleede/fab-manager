module ApplicationHelper

	include Twitter::Autolink
	require 'message_format'

	##
	# Verify if the provided attribute is in the provided attributes array, whatever it exists or not
	# @param attributes {Array|nil}
	# @param attribute {String}
	##
	def attribute_requested?(attributes, attribute)
		attributes.try(:include?, attribute)
	end

	def bootstrap_class_for flash_type
		{ flash: 'alert-success', alert: 'alert-danger', notice: 'alert-info' }[flash_type.to_sym] || flash_type.to_s
	end

	def flash_messages(opts = {})
		flash.each do |msg_type, message|
			concat(content_tag(:div, message, class: "flash-message alert #{bootstrap_class_for(msg_type)} fade in") do
							 concat content_tag(:button, 'x', class: 'close', data: { dismiss: 'alert' })
							 concat message
						 end)
		end
		nil
	end

	def class_exists?(class_name)
		klass = Module.const_get(class_name)
		return klass.is_a?(Class)
	rescue NameError
		return false
	end

	##
	# Allow to treat a rails i18n key as a MessageFormat interpolated pattern. Used in ruby views (API/mails)
	# @param key {String} Ruby-on-Rails I18n key (from config/locales/xx.yml)
	# @param interpolations {Hash} list of variables to interpolate, following ICU MessageFormat syntax
	##
	def _t(key, interpolations)
		message = MessageFormat.new(I18n.t(scope_key_by_partial(key)), I18n.locale.to_s)
		text = message.format(interpolations)
		if html_safe_translation_key?(key)
			text.html_safe
		else
			text
		end
	end

	def bool_to_sym(bool)
		if (bool) then return :true else return :false end
	end

	def amount_to_f(amount)
	  amount / 100.00
	end

  ##
  # Retrieve an item in the given array of items
  # by default, the "id" is expected to match the given parameter but
  # this can be overridden by passing a third parameter to specify the
  # property to match
  ##
	def get_item(array, id, key = nil)
		array.each do |i|
			if key.nil?
				return i if i.id == id
			else
				return i if i[key] == id
			end
		end
		nil
	end


	private
	## inspired by gems/actionview-4.2.5/lib/action_view/helpers/translation_helper.rb
	def scope_key_by_partial(key)
		if key.to_s.first == "."
			if @virtual_path
				@virtual_path.gsub(%r{/_?}, ".") + key.to_s
			else
				raise "Cannot use t(#{key.inspect}) shortcut because path is not available"
			end
		else
			key
		end
	end

	def html_safe_translation_key?(key)
		key.to_s =~ /(\b|_|\.)html$/
	end
end
