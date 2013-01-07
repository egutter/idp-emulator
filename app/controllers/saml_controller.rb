require "base64"
require "zlib"
require "cgi"
require "net/http"
require "uri"

class SamlController < ApplicationController

  ASSERTION = "urn:oasis:names:tc:SAML:2.0:assertion"
  PROTOCOL  = "urn:oasis:names:tc:SAML:2.0:protocol"

  def new
    @account_credential = AccountCredential.new
  end

  def login
    @account_credential = AccountCredential.new(params[:account_credential])
    if @account_credential.valid?
      @redirect_url = "#{params[:protocol]}://#{params[:client]}.#{params[:environment]}.connectedhealth.com/authentication/saml_authentication/idp_response"
      @saml_response = Base64.encode64(saml_xml(@account_credential))
    else
      render :action => "new"
    end
  end

  def login2
    @account_credential = AccountCredential.new(params[:account_credential])
    if @account_credential.valid?

      #redirect_url = "#{params[:protocol]}://#{params[:client]}.#{params[:environment]}.connectedhealth.com/authentication/saml_authentication/idp_response"
      redirect_url = "http://cbc.ch.localhost:3000/authentication/saml_authentication/idp_response"
      #cgi_escaped_saml = CGI.escape(Base64.encode64(saml_xml(@account_credential)))
      saml_response = Base64.encode64(saml_xml(@account_credential))

      uri = URI.parse(redirect_url)

      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.request_uri)
      #request.basic_auth("chstage", "stage%2011")
      request.set_form_data({"SAMLResponse" => saml_response})
      response = http.request(request)

      if response.code == '302'
        all_cookies = response.get_fields('set-cookie').first.split("\;")
        request_params = Array.new
        all_cookies.each { | cookie |
          cookie_array = cookie.split('=')
          cookies[cookie_array[0].to_sym] = cookie_array[1]
        }
        self.headers['Cookie']=response.get_fields('set-cookie')
        redirect_to "#{response['location']}", :pepe => 130
      else
        @account_credential.errors[:base] << "We are sorry, there was a problem performing the login. Please try again"
        render :action => "new"
      end
    else
      render :action => "new"
    end
  end

	def signon
		encoded_saml = params[:SAMLRequest]
    decoded_saml = inflate(Base64.decode64(encoded_saml))

    puts "decoded_saml #{decoded_saml}"

    redirect_url = Nokogiri.XML(decoded_saml).at_xpath('//samlp:AuthnRequest').attribute('AssertionConsumerServiceURL').value
    redirect_url << "?SAMLResponse=#{CGI.escape(Base64.encode64(saml_xml(AccountCredential.instance)))}"
    redirect_to redirect_url

    #raise "#{decoded_saml}"
    #render :text => redirect_url
	end

	def show
		render :text => saml_xml(AccountCredential.instance).html_safe
	end

  def keep_alive
    Rails.logger.info "Keep alive hit - #{Time.now.strftime Time::DATE_FORMATS[:db]}"
    render :text => open(keep_alive_image_path, 'rb').read
  end

  def logout
    Rails.logger.info "Logged out at #{Time.now.strftime Time::DATE_FORMATS[:db]}"
    render :text => 'Logged out!'
  end

  def finish
    Rails.logger.info "Finished at #{Time.now.strftime Time::DATE_FORMATS[:db]}"
    render :text => 'Finish'
  end

  private

  def inflate(string)
    zstream = Zlib::Inflate.new(-Zlib::MAX_WBITS)
    buf = zstream.inflate(string)
    zstream.finish
    zstream.close
    buf
  end

	def saml_xml(account_credential)
		File.read("#{Rails.root}/config/saml_response_without_finish_url.xml").
        gsub('REPLACE_EMPLOYER_ID', account_credential.employer_id).
        gsub('REPLACE_EMPLOYEE_ID', account_credential.employee_id).
        gsub('REPLACE_KEEP_ALIVE_URL', saml_keep_alive_url).
        gsub('REPLACE_FINISH_URL', saml_finish_url).
        gsub('REPLACE_LOGOUT_URL', saml_logout_url)
	end

  def keep_alive_image_path
    'public/images/keep-alive.png'
  end

end
