json.abuses do
  json.array!(@abuses) do |abuse|
    json.extract! abuse, :id, :signaled_id, :signaled_type, :first_name, :last_name, :email, :message, :created_at
    case abuse.signaled_type
    when 'Project'
      json.signaled do
        json.extract! abuse.signaled, :name, :slug, :published_at
        json.author do
          json.id abuse.signaled.author.id
          json.full_name abuse.signaled.author&.user&.profile&.full_name
        end
      end
    else
      json.signaled abuse.signaled
    end
  end
end
