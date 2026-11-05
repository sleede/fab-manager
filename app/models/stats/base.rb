# frozen_string_literal: true

# Typed statistical values only. SearchIndex owns persistence and generated IDs.
class Stats::Base
  include ActiveModel::Model

  class_attribute :stat_fields, default: {}.freeze
  attr_accessor :id, :created_at, :updated_at

  def self.attribute(name, type)
    self.stat_fields = stat_fields.merge(name.to_s => type).freeze
    define_method(name) { self[name] }
    define_method("#{name}=") { |value| self[name] = value }
  end

  def self.family
    name.demodulize.underscore
  end

  def initialize(values = {})
    @attributes = self.class.stat_fields.transform_values do |type|
      if type == Array
        []
      elsif type == Hash
        {}
      end
    end
    super
  end

  def [](name)
    @attributes.fetch(name.to_s)
  end

  def []=(name, value)
    type = self.class.stat_fields.fetch(name.to_s)
    @attributes[name.to_s] = if value.nil?
                               nil
                             elsif type == String
                               value.to_s
                             elsif type == Integer
                               Integer(value)
                             elsif type == Float
                               Float(value)
                             else
                               value
                             end
  end

  def as_json(_options = nil)
    @attributes.merge('created_at' => created_at, 'updated_at' => updated_at).as_json
  end

  def persisted?
    id.present?
  end
end
