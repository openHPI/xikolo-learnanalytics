class Account::ProfilePresenter < Presenter
  include Rails.application.routes.url_helpers
  include UserVisualHelper
  include Xikolo::Account

  attr_accessor :profile, :user, :emails, :authorizations, :gamification

  def_delegators :gamification, :badges, :points_by_course

  def initialize(user)
    @user = user
    @emails = Email.where(user_id: user.id)
    @profile = Profile.find(user_id: user.id)
    @authorizations = Authorization.where(user: user.id)

    @gamification = Hashie::Mash.new # Keep delegation working

  end

  def initialize_gamification(user)

  end

  def user_id
    @user.id
  end

  def visual_path(size = nil)
    user_visual_path(@user.image_id, size)
  end

  def full_name
    "#{@user.first_name} #{@user.last_name}"
  end

  def first_name
    @user.first_name
  end

  def last_name
    @user.last_name
  end

  def display_name
    @user.display_name
  end

  def name
    @user.name
  end

  def email
    @user.email
  end

  def born_at
    @user.born_at
  end

  def unconfirmed_emails?
    unconfirmed_emails.any?
  end

  def unconfirmed_emails
    emails.select{|e| !e.confirmed }
  end

  def secondary_emails?
    secondary_emails.any?
  end

  def secondary_emails
    emails.select{|e| e.confirmed && !e.primary}
  end

  def field?(name)
    @profile.fields.key?(name)
  end

  def field(name)
    if field?(name)
      FieldPresenter.new @profile.fields.fetch(name)
    else
      raise ArgumentError.new "Profile does not have field: #{name}"
    end
  end

  def fields
    @profile.fields.map{|name, field| FieldPresenter.new(field) }
  end

  def points_per_course
    @user_scores
  end

  class FieldPresenter
    def initialize(field)
      @field = field
    end

    def available_values_json
      @field.available_values.map do |val|
        {value: val, text: I18n.t("dashboard.profile.settings.#{@field.name}.#{val}")}
      end.to_json
    end

    def name
      @field.name
    end

    def to_bool(default = false)
      if @field.value.nil?
        default
      else
        @field.value == 'true'
      end
    end

    def value
      @field.value.to_s
    end

    def select?
      @field.type == 'CustomSelectField'
    end

    def text?
      @field.type == 'CustomTextField'
    end
  end
end
