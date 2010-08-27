# DeRose Connect Client (DRCClient) requires rubycas-client
require 'casclient'
require 'casclient/frameworks/rails/filter'

module DRCClient

  def self.filter(opts={})
    gateway = opts.delete(:gateway)
    if gateway
      CASClient::Frameworks::Rails::GatewayFilter
    else
      CASClient::Frameworks::Rails::Filter
    end
  end

  def self.configure(config)
    base_url = config.delete(:base_url)
    config.merge!({:cas_base_url => base_url, :extra_attributes_session_key => :cas_extra_attributes})
    CASClient::Frameworks::Rails::Filter.configure(config)
  end

  def self.logout(controller,service=nil)
    CASClient::Frameworks::Rails::Filter.logout(controller,service)
  end

  module HelperMethods

    def self.included(base)
      base.send :helper_method, :logged_in_drc?, :cas_is_pama_allowed?, :cas_has_padma_user?, :login_with_cas, :drc_logout_url, :drc_login_url
    end

    def current_drc_user
      return session[:cas_user]
    end

    # check if session has CAS credentials
    def logged_in_drc?
      return !session[:cas_user].blank?
    end

    # TODO this is app specific, refactor to allow usage in various apps
    # checks if CAS credentials have access to PADMA
    def cas_is_padma_allowed?
      return (logged_in_drc? && !session[:cas_extra_attributes].blank? && session[:cas_extra_attributes]["padma_access"].to_s == "true")
    end

    # TODO this is app specific, refactor to allow usage in various apps
    # get padma-user with cas login
    # returns User object or nil
    def get_padma_user
      return nil unless logged_in_drc?
      return User.find_by_cas_login(session[:cas_user])
    end


    # checks if cas_user matches any padma_user
    def cas_has_padma_user?
      return get_padma_user.nil?
    end

    # TODO this is app specific, extract out from this lib.
    # attempt login user using it's CAS credential
    # returns true if achieved login, false if it didn't
    def login_with_cas
      if logged_in_drc? && cas_is_padma_allowed?
	u = get_padma_user
	self.current_user = u.nil?? :false : u
	self.current_school = u.schools.last unless u.nil?
	add_flash_message(:notice, I18n.t('cas_integration.logged_in_with_cas',
					  :cas_user => current_drc_user,
					  :drc_logout_url => drc_logout_url))
      end
      return logged_in?
    end

    # returns login url to CAS server.
    def drc_login_url
      return CASClient::Frameworks::Rails::Filter.login_url(self)
    end

    # TODO this is app specific, extract out from this lib.
    def drc_logout_url
      return url_for({:controller => 'account', :action => 'logout_cas'})
    end
  end
end
