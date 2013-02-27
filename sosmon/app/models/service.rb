class Service < ActiveRecord::Base
  belongs_to :client
  has_many :tests
  attr_accessible :desc, :name, :portfolio, :tags

  alias_attribute :to_s, :name
end
