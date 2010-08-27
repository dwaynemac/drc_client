# DeRose Connect Client (DRCClient) requires rubycas-client
require 'casclient'
require 'casclient/frameworks/rails/filter'

module DRCClient

  # These are initialized when you call configure
  @@base_url = nil
  @@drc_config = {
    :user_model => nil,
    :drc_user_column => nil,
    :auth_attribute_name => nil,
    :required_access_level => nil # none, student, teacher, director, federation_president
  }

  def self.filter(opts={})
    gateway = opts.delete(:gateway)
    if gateway
      CASClient::Frameworks::Rails::GatewayFilter
    else
      CASClient::Frameworks::Rails::Filter
    end
  end

  def self.configure(configuration)
    @@base_url = configuration.delete(:base_url)
    @@drc_config[:user_model] = configuration.delete(:user_model)
    @@drc_config[:drc_user_column] = configuration.delete(:drc_user_column) || :drc_user
    @@drc_config[:auth_attribute_name] = configuration.delete(:auth_attribute_name)
    @@drc_config[:required_access_level] = configuration.delete(:required_access_level)
    configuration.merge!({:cas_base_url => @@base_url, :extra_attributes_session_key => :cas_extra_attributes})
    CASClient::Frameworks::Rails::Filter.configure(configuration)
  end

  def self.logout(controller,service=nil)
    CASClient::Frameworks::Rails::Filter.logout(controller,service)
  end

  def self.config
    return @@drc_config
  end
  
  module HelperMethods

    def self.included(base)
      base.send :helper_method, :logged_in_drc?, :cas_is_pama_allowed?, :drc_user_has_local_user?, :login_with_drc, :drc_logout_url, :drc_login_url
    end

    def current_drc_user
      return session[:cas_user]
    end

    # check if session has DRC credentials
    def logged_in_drc?
      return !session[:cas_user].blank?
    end

    # checks if DRC credentials have access to local application
    def allowed_drc_user?
      return false if !logged_in_drc?
      # by default having a drc_user is enough
      allowed = true
      if DRCClient.config[:required_access_level]
        allowed = true # TODO check drc_user has sufficient access_level
      elsif DRCClient.config[:auth_attribute_name]
        allowed =  (!session[:cas_extra_attributes].blank? && session[:cas_extra_attributes][DRCClient.config[:auth_attribute_name]].to_s == "true")
      end
      return allowed
    end

    # finds local user that matches logged in DRC user
    # return user's id
    def get_local_user_id
      return nil if DRCClient.config[:user_model].nil?
      return nil unless logged_in_drc?
      user = DRCClient.config[:user_model].find(:first, :conditions => { DRCClient.config[:drc_user_column] => current_drc_user})
      if user
        return user[:id]
      else
        return nil
      end
    end

    # checks if cas_user matches any padma_user
    def drc_user_has_local_user?
      return get_local_user.nil?
    end

    # returns login url to DRC server.
    def drc_login_url
      return CASClient::Frameworks::Rails::Filter.login_url(self)
    end
  end
end
