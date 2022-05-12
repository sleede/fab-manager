# frozen_string_literal: true

# Check the access policies for API::ProofOfIdentityRefusalsController
class ProofOfIdentityRefusalPolicy < ApplicationPolicy
  def index?
    user.privileged?
  end

  def create?
    user.privileged?
  end

  def show?
    user.privileged?
  end
end
