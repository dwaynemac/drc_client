# DeRose Connect Client (DRCClient) requires rubycas-client
require 'casclient'
require 'casclient/frameworks/rails/filter'

module DRCClient

  # These are initialized when you call configure
  @@drc_config = {
    :base_url => nil,
    :enable_single_sign_out => nil,
    :user_model => nil,
    :drc_user_column => nil,
    :local_user_id_column => nil,
    :require_local_user => nil,
    :require_access_level => nil # none, student, teacher, director, federation_president
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
    @@drc_config[:base_url] = configuration.delete(:base_url)
    @@drc_config[:enable_single_sign_out] = configuration.delete(:enable_single_sign_out) || false
    @@drc_config[:user_model] = configuration.delete(:user_model)
    @@drc_config[:drc_user_column] = configuration.delete(:drc_user_column) || :drc_user
    @@drc_config[:require_local_user] = configuration.delete(:require_local_user)
    @@drc_config[:require_access_level] = configuration.delete(:require_access_level)
    @@drc_config[:local_user_id_column] = configuration.delete(:local_user_id_column) || :id

    configuration.merge!({:cas_base_url => @@drc_config[:base_url],
                          :enable_single_sign_out => @@drc_config[:enable_single_sign_out]})
    CASClient::Frameworks::Rails::Filter.configure(configuration)
  end

  def self.logout(controller,service=nil)
    CASClient::Frameworks::Rails::Filter.logout(controller,service)
  end

  def self.config
    return @@drc_config
  end

  def self.mock_login(username)
    CASClient::Frameworks::Rails::Filter.fake(username)
  end
  
  module HelperMethods

    def self.included(base)
      base.send :helper_method, :logged_in_drc?, :cas_is_pama_allowed?, :current_drc_user,
                :drc_user_has_local_user?, :login_with_drc, :drc_logout_url, :drc_login_url
    end

    def current_drc_user
      return session[:cas_user]
    end

    # check if session has DRC credentials
    def logged_in_drc?
      return !current_drc_user.blank?
    end

    # checks if DRC credentials have access to local application
    def allowed_drc_user?
      return false if !logged_in_drc?
      allowed = true # by default having a drc_user is enough
      allowed &&= drc_user_has_local_user? if DRCClient.config[:require_local_user]
      allowed &&= true if DRCClient.config[:require_access_level] # TODO
      return allowed
    end

    # finds local user that matches logged in DRC user
    # return user's id or nil if none found
    def get_local_user_id
      return nil if DRCClient.config[:user_model].nil?
      return nil unless logged_in_drc?
      user = DRCClient.config[:user_model].find(:first,
                                              :select => DRCClient.config[:local_user_id_column],
                                              :conditions => { DRCClient.config[:drc_user_column] => current_drc_user})
      if user
        return user[DRCClient.config[:local_user_id_column].to_sym]
      else
        return nil
      end
    end

    # checks if drc_user matches any local application user.
    def drc_user_has_local_user?
      return !get_local_user_id.nil?
    end

    # returns login url to DRC server.
    def drc_login_url
      return CASClient::Frameworks::Rails::Filter.login_url(self)
    end
    
    def drc_logout_url
      return DRCClient.config[:base_url]+"/logout" # TODO strip posible / at end of base_url
    end
    
  end
end
