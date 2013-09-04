require "base64"
require "zlib"
require "cgi"
require "net/http"
require "uri"

class SamlController < ApplicationController
  protect_from_forgery :except => [:echo_name_id]

  ASSERTION = "urn:oasis:names:tc:SAML:2.0:assertion"
  PROTOCOL  = "urn:oasis:names:tc:SAML:2.0:protocol"

  EVOLUTION_ONE_CLIENTS = %w(intuit assurant paychex)

  def new
    @account_credential = AccountCredential.new(params[:account_credential])
    @client = params[:client]
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
      saml_xml = if EVOLUTION_ONE_CLIENTS.include?(client)
          evo_one_saml_xml(@account_credential)
        elsif client == 'cbcffma'
          cbcffma_saml_xml(@account_credential)
        elsif client == 'cbcffmr'
          cbcffmr_saml_xml(@account_credential)
        else
          saml_xml(@account_credential)
        end
      @saml_response = Base64.encode64(saml_xml)
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

  def echo_name_id
    xml = Nokogiri::XML(Base64.decode64(params['SAMLResponse']))
    xml.remove_namespaces!
    name_id = xml.at_xpath('//Attribute[@Name="ShoppingCartID"]/AttributeValue').try(:text) 
    render text: name_id.blank? ? "No name id present!" : "Login with the following uuid <a href='#{saml_new_path}?client=cbcffmr&account_credential[uuid]=#{name_id}&account_credential[employee_id]=a&account_credential[employer_id]=b'>here</a>: #{name_id}"
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
      gsub('REPLACE_ADMINISTRATOR_ALIAS', account_credential.administrator_alias).
      gsub('REPLACE_PLAN_YEAR_NAME', account_credential.plan_year_name).
      gsub('REPLACE_PLAN_YEAR_START', account_credential.plan_year_start).
      gsub('REPLACE_AGENT_NAME', account_credential.agent_name).
      gsub('REPLACE_AGENT_PHONE', account_credential.agent_phone).
      gsub('REPLACE_AGENT_CODE', account_credential.agent_code)
  end

  def cbcffmr_saml_xml(account_credential)
    File.read("#{Rails.root}/config/cbcffmr_saml_response.xml").
      gsub('REPLACE_PARTNER_TOKEN', "whatever").#account_credential.partner_token).
      gsub('REPLACE_RETURN_URL', saml_echo_name_id_url).
      gsub('REPLACE_CLIENT_ID', account_credential.uuid).
      gsub('REPLACE_CART_ID', account_credential.uuid)
  end

  def cbcffma_saml_xml(account_credential)
    File.read("#{Rails.root}/config/cbcffma_saml_response.xml").
      gsub('REPLACE_PARTNER_TOKEN', "whatever").#account_credential.partner_token).
      gsub('REPLACE_RETURN_URL', saml_echo_name_id_url).
      gsub('REPLACE_CLIENT_ID', "").
      gsub('REPLACE_CART_ID', "")
  end

  def keep_alive_image_path
    'public/images/keep-alive.png'
  end
end
