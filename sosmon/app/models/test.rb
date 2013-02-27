class Test < ActiveRecord::Base
  belongs_to :service
  attr_accessible :check_url, :enabled, :name, :opmode, :status, :tags, :uuid
end
