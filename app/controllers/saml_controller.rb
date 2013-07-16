require "base64"
require "zlib"
require "cgi"
require "net/http"
require "uri"

class SamlController < ApplicationController

  ASSERTION = "urn:oasis:names:tc:SAML:2.0:assertion"
  PROTOCOL  = "urn:oasis:names:tc:SAML:2.0:protocol"

  EVOLUTION_ONE_CLIENTS = %w(intuit assurant)

  def new
    @account_credential = AccountCredential.new
  end

  def login
    @account_credential = AccountCredential.new(params[:account_credential])
    if params[:client_custom].empty?
      client = params[:client]
    else
      client = params[:client_custom]
    end
    if @account_credential.valid?
      @redirect_url = "#{params[:protocol]}://#{client}.#{params[:environment]}:#{params[:port]}/authentication/saml_authentication/idp_response"
      saml_xml = EVOLUTION_ONE_CLIENTS.include?(client) ? evo_one_saml_xml(@account_credential) : saml_xml(@account_credential)
      @saml_response = Base64.encode64(saml_xml)
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

    response = Base64.encode64 File.read("#{Rails.root}/config/slo_successful_response.xml")

    referer_url = URI(request.referer)
    redirect_to "#{referer_url.scheme}://#{referer_url.host}:#{referer_url.port}/authentication/saml_authentication/slo_response?SAMLResponse=#{response}"
  end

  def finish
    Rails.logger.info "Finished at #{Time.now.strftime Time::DATE_FORMATS[:db]}"
    render :text => 'Finish'
  end

  def slo
    enc_saml_response = params[:SAMLRequest]
    decoded_saml_response = Base64.decode64(enc_saml_response)

    if params['Signature'].present?
      pub_key_file = File.read "#{Rails.root}/config/rsa_keys/id_rsa.pub"
      public_key = OpenSSL::PKey::RSA.new(pub_key_file, nil)

      signature = Base64.decode64(params['Signature'])
      encoded_sig_alg = CGI.escape(params['SigAlg'])
      encoded_request   = CGI.escape(enc_saml_response)
      url_string = "SAMLRequest=#{encoded_request}&SigAlg=#{encoded_sig_alg}"
      valid_signature = public_key.verify(OpenSSL::Digest::SHA1.new, signature, url_string)

      inflated_saml_response = inflate(decoded_saml_response)
      render :text => "Successful SLO<br/>Valid signature? #{valid_signature}<br/>SAML Request received:<br/>#{ERB::Util.html_escape(inflated_saml_response)}"
    else
      render :text => "Successful SLO<br/>SAML Request received:<br/>#{ERB::Util.html_escape(inflate(decoded_saml_response))}"
    end
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
      gsub('REPLACE_NAME_ID', account_credential.name_id || '').
      gsub('REPLACE_KEEP_ALIVE_URL', saml_keep_alive_url).
      gsub('REPLACE_FINISH_URL', saml_finish_url).
      gsub('REPLACE_LOGOUT_URL', saml_logout_url)
  end
  
  def evo_one_saml_xml(account_credential)
    File.read("#{Rails.root}/config/evo_one_saml_response.xml").
      gsub('REPLACE_EMPLOYER_CODE', account_credential.employer_id).
      gsub('REPLACE_CONSUMER_IDENTIFIER', account_credential.employee_id).
      gsub('REPLACE_NAME_ID', account_credential.name_id || '').
      gsub('REPLACE_PLAN_YEAR_NAME', account_credential.plan_year_name).
      gsub('REPLACE_PLAN_YEAR_START', account_credential.plan_year_start)
  end

  def keep_alive_image_path
    'public/images/keep-alive.png'
  end

end
