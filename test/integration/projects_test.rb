# frozen_string_literal: true

require 'test_helper'

class ProjectsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'download markdown file' do
    get "/api/projects/1/markdown"

    assert_response :success
    assert_equal "text/markdown", response.content_type
  end

  test 'anonymous visitor cannot access draft project by id or slug' do
    draft_project = Project.create!(
      name: 'Secret Draft Project',
      description: '<p>Top secret draft description</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'draft'
    )

    logout

    get "/api/projects/#{draft_project.id}"
    assert_response :forbidden

    get "/api/projects/#{draft_project.slug}"
    assert_response :forbidden
  end

  test 'unrelated member cannot access draft project by id or slug' do
    draft_project = Project.create!(
      name: 'Private Member Draft',
      description: '<p>Private draft</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'draft'
    )

    unrelated_member = User.where.not(id: [5, @admin.id]).first
    login_as(unrelated_member, scope: :user)

    get "/api/projects/#{draft_project.id}"
    assert_response :forbidden

    get "/api/projects/#{draft_project.slug}"
    assert_response :forbidden
  end

  test 'author can access draft project by id and slug' do
    draft_project = Project.create!(
      name: 'Author Own Draft',
      description: '<p>Author draft</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'draft'
    )

    author = User.find(5)
    login_as(author, scope: :user)

    get "/api/projects/#{draft_project.id}"
    assert_response :success
    assert_equal draft_project.id, json_response(response.body)[:id]

    get "/api/projects/#{draft_project.slug}"
    assert_response :success
    assert_equal draft_project.id, json_response(response.body)[:id]
  end

  test 'collaborator can access draft project by id and slug' do
    draft_project = Project.create!(
      name: 'Collaborator Draft Project',
      description: '<p>Collaborative work</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'draft'
    )

    collaborator = User.where.not(id: [5, @admin.id]).last
    draft_project.project_users.create!(user: collaborator, is_valid: true)

    login_as(collaborator, scope: :user)

    get "/api/projects/#{draft_project.id}"
    assert_response :success
    assert_equal draft_project.id, json_response(response.body)[:id]

    get "/api/projects/#{draft_project.slug}"
    assert_response :success
    assert_equal draft_project.id, json_response(response.body)[:id]
  end

  test 'admin can access draft project by id and slug' do
    draft_project = Project.create!(
      name: 'Admin Draft Inspection',
      description: '<p>Admin draft inspection</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'draft'
    )

    login_as(@admin, scope: :user)

    get "/api/projects/#{draft_project.id}"
    assert_response :success
    assert_equal draft_project.id, json_response(response.body)[:id]

    get "/api/projects/#{draft_project.slug}"
    assert_response :success
    assert_equal draft_project.id, json_response(response.body)[:id]
  end

  test 'any visitor can access published project by id and slug' do
    published_project = projects(:project_1)

    logout

    get "/api/projects/#{published_project.id}"
    assert_response :success
    assert_equal published_project.id, json_response(response.body)[:id]

    get "/api/projects/#{published_project.slug}"
    assert_response :success
    assert_equal published_project.id, json_response(response.body)[:id]
  end

  test 'transitioning from published to draft revokes visitor and third-party access' do
    project = Project.create!(
      name: 'State Transition Project',
      description: '<p>Testing state change</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'published'
    )

    logout

    # Initially published: visitor can view
    get "/api/projects/#{project.id}"
    assert_response :success

    # Move back to draft
    project.update!(state: 'draft')

    # Visitor denied
    get "/api/projects/#{project.id}"
    assert_response :forbidden

    get "/api/projects/#{project.slug}"
    assert_response :forbidden

    # Third-party member denied
    third_party = User.where.not(id: [5, @admin.id]).first
    login_as(third_party, scope: :user)

    get "/api/projects/#{project.id}"
    assert_response :forbidden

    get "/api/projects/#{project.slug}"
    assert_response :forbidden
  end

  test 'social bot endpoint never serves draft projects' do
    draft = Project.create!(
      name: 'Bot Draft Test',
      description: '<p>Secret draft</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'draft'
    )

    get "/?_escaped_fragment_=/projects/#{draft.id}", headers: { 'HTTP_USER_AGENT' => 'Twitterbot/1.0' }
    assert_response :not_found

    get "/?_escaped_fragment_=/projects/#{draft.slug}", headers: { 'HTTP_USER_AGENT' => 'Twitterbot/1.0' }
    assert_response :not_found

    published = Project.create!(
      name: 'Published Project Test',
      description: '<p>Published description</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'published'
    )
    get "/?_escaped_fragment_=/projects/#{published.id}", headers: { 'HTTP_USER_AGENT' => 'Twitterbot/1.0' }
    assert_response :success
  end

  test 'project search by member_id does not leak draft projects to unauthorized visitors' do
    draft = Project.create!(
      name: 'Member Secret Draft',
      description: '<p>Secret draft</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'draft'
    )

    collab_draft = Project.create!(
      name: 'Member Collab Secret Draft',
      description: '<p>Collab secret draft</p>',
      author: StatisticProfile.where.not(id: 5).first,
      licence_id: 1,
      status_id: 1,
      state: 'draft'
    )
    collab_draft.project_users.create!(user: User.find(5), is_valid: true)

    logout

    get '/api/projects/search', params: { search: { member_id: 5 }.to_json }, headers: default_headers
    assert_response :success
    results = json_response(response.body)
    project_ids = results[:projects].map { |p| p[:id] }
    refute_includes project_ids, draft.id
    refute_includes project_ids, collab_draft.id

    login_as(User.find(5), scope: :user)
    get '/api/projects/search', params: { search: { member_id: 5 }.to_json }, headers: default_headers
    assert_response :success
    results = json_response(response.body)
    project_ids = results[:projects].map { |p| p[:id] }
    assert_includes project_ids, draft.id
  end

  test 'ProjectPolicy::Scope resolves appropriately for managers, admins, and users without profile' do
    draft = Project.create!(
      name: 'Scope Draft Test',
      description: '<p>Scope test</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'draft'
    )

    # Admin scope includes draft
    admin_scope = Pundit.policy_scope(@admin, Project)
    assert_includes admin_scope, draft

    # Manager scope includes draft
    manager = User.find(2)
    manager.roles << Role.find_or_create_by!(name: 'manager') unless manager.roles.exists?(name: 'manager')
    manager_scope = Pundit.policy_scope(manager, Project)
    assert_includes manager_scope, draft

    # User without statistic_profile does not crash and excludes other draft
    profileless_user = User.new(id: 99_999)
    profileless_scope = Pundit.policy_scope(profileless_user, Project)
    refute_includes profileless_scope, draft
  end
end