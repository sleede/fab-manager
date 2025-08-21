# frozen_string_literal: true

require 'faraday'
require 'json'

# Service to fetch and merge projects from multiple DoDoc APIs
class DoDocProjectsService
  def initialize
    @api_key = Setting.get('dodoc_api_key')
  end

  # Search projects across all DoDoc APIs
  # @param query [String] search query (optional)
  # @param page [Integer] page number for pagination
  # @param per_page [Integer] items per page
  # @return [Hash] paginated results with projects
  def search(query = nil, page: 1, per_page: 20)
    all_projects = fetch_all_projects
    filtered_projects = filter_projects(all_projects, query)
    paginate_results(filtered_projects, page, per_page)
  end

  # build project data to the required format
  # @param project [Hash] project data from DoDoc API
  # @param do_doc [DoDoc] DoDoc model instance
  # @return [Hash] builded project data
  def build_project(project, do_doc)
    base_url = extract_base_url(do_doc.url)
    project['do_doc_name'] = do_doc.name
    project['project_image'] = build_image_url(project, base_url)
    project['project_url'] = build_project_url(project, base_url)
  end

  private

  # Extract base URL from DoDoc API URL
  # @param api_url [String] DoDoc API URL
  # @return [String] base URL
  def extract_base_url(api_url)
    uri = URI(api_url)
    "#{uri.scheme}://#{uri.host}#{uri.port == uri.default_port ? '' : ":#{uri.port}"}"
  end

  # Build image URL from project cover data
  # @param project [Hash] project data
  # @param base_url [String] base URL
  # @return [String] image URL
  def build_image_url(project, base_url)
    return '' unless project['$cover'] && project['$cover']['640'] && project['$path']

    "#{base_url}/thumbs/#{project['$path']}/#{project['$cover']['640']}"
  end

  # Build project URL
  # @param project [Hash] project data
  # @param base_url [String] base URL
  # @return [String] project URL
  def build_project_url(project, base_url)
    return '' unless project['$path']

    # Transform path format: spaces/hello-test/projects/do-doc -> +hello-test/do-doc
    path = project['$path']
    if path.start_with?('spaces/')
      # Remove 'spaces/' prefix and replace 'projects/' with '/'
      transformed_path = path.sub(%r{^spaces/}, '+').sub('/projects/', '/')
      "#{base_url}/#{transformed_path}"
    else
      "#{base_url}/#{path}"
    end
  end

  # Fetch projects from all DoDoc API URLs
  # @return [Array] array of all projects from all APIs
  def fetch_all_projects
    all_projects = []

    DoDoc.all.each do |do_doc|
      projects = fetch_projects_from_api(do_doc.url)
      projects.each { |project| build_project(project, do_doc) } if projects.is_a?(Array)
      # Concatenate projects to the all_projects array
      all_projects.concat(projects) if projects.is_a?(Array)
    rescue StandardError => e
      Rails.logger.error "Failed to fetch projects from #{do_doc.url}: #{e.message}"
      # Continue with other APIs even if one fails
    end

    # Filter only finished projects and sort by date_modified
    finished_projects = all_projects.select { |project| project['$status'] == 'finished' }
    finished_projects.sort_by { |project| project['$date_modified'] || '1970-01-01T00:00:00.000Z' }.reverse
  end

  # Fetch projects from a single DoDoc API
  # @param api_url [String] the DoDoc API URL
  # @return [Array] array of projects from the API
  def fetch_projects_from_api(api_url)
    # Ensure URL ends with /projects if it doesn't already
    url = api_url.end_with?('/projects') ? api_url : "#{api_url.chomp('/')}/projects"

    connection = Faraday.new do |faraday|
      faraday.options.timeout = 30
      faraday.options.open_timeout = 10
      faraday.adapter Faraday.default_adapter
    end

    headers = { 'Accept' => 'application/json' }
    headers['Authorization'] = "Bearer #{@api_key}" if @api_key

    response = connection.get(url) do |req|
      req.headers = headers
    end

    if response.status == 200
      JSON.parse(response.body)
    else
      Rails.logger.error "DoDoc API returned status #{response.status} for #{url}"
      []
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching from DoDoc API #{url}: #{e.message}"
    []
  end

  # Filter projects based on search query
  # @param projects [Array] array of projects
  # @param query [String] search query
  # @return [Array] filtered projects
  def filter_projects(projects, query)
    return projects if query.blank?

    query_downcase = query.downcase
    projects.select do |project|
      # Search in title, description, keywords

      project['title']&.downcase&.include?(query_downcase) ||
        project['description']&.downcase&.include?(query_downcase) ||
        project['keywords']&.any? { |keyword| keyword.downcase.include?(query_downcase) }
    end
  end

  # Paginate the results
  # @param projects [Array] array of projects
  # @param page [Integer] page number
  # @param per_page [Integer] items per page
  # @return [Hash] paginated results
  def paginate_results(projects, page, per_page)
    page = [page.to_i, 1].max
    per_page = [[per_page.to_i, 1].max, 100].min # Limit per_page to max 100

    total_count = projects.length
    total_pages = (total_count.to_f / per_page).ceil
    offset = (page - 1) * per_page

    paginated_projects = projects[offset, per_page] || []

    {
      projects: paginated_projects,
      meta: {
        page: page,
        per_page: per_page,
        total_pages: total_pages,
        total: total_count
      }
    }
  end
end
