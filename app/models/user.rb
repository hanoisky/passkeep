# == Schema Information
#
# Table name: users
#
#  id                     :integer         not null, primary key
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(128)     default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer         default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  password_salt          :string(255)
#  failed_attempts        :integer         default(0)
#  unlock_token           :string(255)
#  locked_at              :datetime
#  first_name             :string(255)     not null
#  last_name              :string(255)     not null
#  guid                   :string(36)      not null
#  time_zone              :string(255)     default("Eastern Time (US & Canada)")
#  super_user             :boolean         default(FALSE)
#  administrator          :boolean         default(FALSE)
#  created_at             :datetime        not null
#  updated_at             :datetime        not null
#

class User < ActiveRecord::Base

  acts_as_tagger

  # Include default devise modules. Others available are:
  # :registerable, :confirmable, :token_authenticatable, :timeoutable and :omniauthable
  devise :database_authenticatable, :lockable, :encryptable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :team_members
  has_many :teams, through: :team_members
  has_many :projects, through: :teams, uniq: true
  has_many :entries, through: :projects, uniq: true
#  has_many :edit_teams, class_name: "Team", source: :user,
#           through: :team_members, conditions: "role_id = 2"

  attr_accessible :email, :password, :password_confirmation, :remember_me,
                  :first_name, :last_name, :full_name, :time_zone, :team_tokens,
                  :administrator, :super_user

  attr_accessor :full_name
  attr_accessor :team_tokens

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :guid, presence: true

  before_validation :make_guid

  def admin?
    super_user || administrator
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def full_name=(n)
    split = n.split(' ', 2)
    self.first_name = split.first
    self.last_name = split.last
  end

  def team_tokens=(ids)
    self.team_ids = ids.split(",")
  end

  def team_tokens
    return self.team_ids.join(',')
  end

  def to_param
    self.guid
  end

  def can_edit?(p)
    return true if p.new_record?
    user_teams = self.teams.where(role_id: 2).select("teams.id").collect(&:id)
    project_teams = p.teams.where(role_id: 2).select("teams.id").collect(&:id)
    (user_teams & project_teams).length > 0
  end

  private
    def make_guid
      self.guid = UUIDTools::UUID.random_create.to_s if guid.blank?
    end

  protected
    def password_required?
      !persisted? || password.present? || password_confirmation.present?
    end

  class << self
    def ordered
      order("users.last_name, users.first_name")
    end

    def skinny
      select("users.id, users.guid, email, users.first_name, users.last_name")
    end
  end
end
