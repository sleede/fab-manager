class ExportPolicy < Struct.new(:user, :export)
  %w(export_members).each do |action|
    define_method "#{action}?" do
      user.is_admin?
    end
  end
end
