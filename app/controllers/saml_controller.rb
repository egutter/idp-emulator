require "base64"
require "zlib"
require "cgi"

class SamlController < ApplicationController

  ASSERTION = "urn:oasis:names:tc:SAML:2.0:assertion"
  PROTOCOL  = "urn:oasis:names:tc:SAML:2.0:protocol"

  def new
    @account_credential = AccountCredential.new
  end

  def login
    @account_credential = AccountCredential.new(params[:account_credential])
    if @account_credential.valid?
      redirect_url = "#{params[:protocol]}://#{params[:client]}.#{params[:environment]}.connectedhealth.com/authentication/saml_authentication/idp_response"
      cgi_escaped_saml = CGI.escape(Base64.encode64(saml_xml(@account_credential)))
      redirect_url << "?SAMLResponse=#{cgi_escaped_saml}"
      #render :text => redirect_url
      redirect_to redirect_url
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
