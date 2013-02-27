class Client < ActiveRecord::Base
  has_many :services
  attr_accessible :name

  alias_attribute :to_s, :name
end
