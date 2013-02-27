class Service < ActiveRecord::Base
  belongs_to :client
  attr_accessible :desc, :name, :portfolio, :tags
end
