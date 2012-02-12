# == Schema Information
#
# Table name: projects
#
#  id         :integer         not null, primary key
#  guid       :string(36)      not null
#  name       :string(255)     not null
#  status_id  :integer         default(1), not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

class Project < ActiveRecord::Base

  before_validation :make_guid

  has_many :entries
  has_many :team_projects
  has_many :teams, :through => :team_projects

  attr_accessible :name, :status_id

  def to_param
    self.guid
  end

  private
    def make_guid
      self.guid = UUIDTools::UUID.random_create.to_s if guid.blank?
    end

end