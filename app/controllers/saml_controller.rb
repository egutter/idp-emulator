require "base64"
require "zlib"
require "cgi"
require "net/http"
require "uri"

class SamlController < ApplicationController
  protect_from_forgery :except => [:echo_name_id]

  ASSERTION = "urn:oasis:names:tc:SAML:2.0:assertion"
  PROTOCOL = "urn:oasis:names:tc:SAML:2.0:protocol"

  EVOLUTION_ONE_CLIENTS = %w(advantage assurant)

  PRESET_LOGINS = {
    "Assurant 0003237014" => {
      "account_credential_employer_id" => "AHITST",
      "account_credential_employee_id" => "0032.00101.0000056277.0003237014",
      "account_credential_administrator_alias" => "AHI",
      "account_credential_plan_year_name" => "AHI01012014",
      "account_credential_plan_year_start" => "01/01/2014 00:00:00",
      "account_credential_agent_phone" => "123-456-7890",
      "account_credential_agent_code" => "00013311000001",
      "client" => "assurant",
      "saml_type" => "evo_one",
    },
    "CBCFFMa" => {
      "client" => "cbcffma",
      "account_credential_employer_id" => "a",
      "account_credential_employee_id" => "b",
      "saml_type" => "cbcffma",
    },
    "CBCFFMr - Off Exchange" => {
      "client" => "cbcffmr",
      "account_credential_employer_id" => "a",
      "account_credential_employee_id" => "b",
      "account_credential_ffm_lastname" => "Wolfe",
      "account_credential_ffm_consumerid" => "",
      "account_credential_ffm_partner_consumerid" => "4485",
      "account_credential_ffm_firstname" => "Steve",
      "account_credential_ffm_partner_token" => "101",
      "account_credential_ffm_usertype" => "Consumer",
      "saml_type" => "cbcffmr",
    },
    "CBCFFMr - Brief Englandpaa" => {
      "client" => "cbcffmr",
      "account_credential_employer_id" => "a",
      "account_credential_employee_id" => "b",
      "account_credential_ffm_lastname" => "Wolfe",
      "account_credential_ffm_consumerid" => "94658488",
      "account_credential_ffm_partner_consumerid" => "4485",
      "account_credential_ffm_firstname" => "Steve",
      "account_credential_ffm_partner_token" => "101",
      "account_credential_ffm_usertype" => "Consumer",
      "saml_type" => "cbcffmr",
    },
    "CBCFFMr - Yellow Lindsaypaa" => {
      "client" => "cbcffmr",
      "account_credential_employer_id" => "a",
      "account_credential_employee_id" => "b",
      "account_credential_ffm_lastname" => "Wolfe",
      "account_credential_ffm_consumerid" => "94914271",
      "account_credential_ffm_partner_consumerid" => "4807",
      "account_credential_ffm_firstname" => "Steve",
      "account_credential_ffm_partner_token" => "101",
      "account_credential_ffm_usertype" => "Consumer",
      "saml_type" => "cbcffmr",
    },
    "CBCFFMr - Great Summerspab" => {
      "client" => "cbcffmr",
      "account_credential_employer_id" => "a",
      "account_credential_employee_id" => "b",
      "account_credential_ffm_lastname" => "Wolfe",
      "account_credential_ffm_consumerid" => "94733503",
      "account_credential_ffm_partner_consumerid" => "4796",
      "account_credential_ffm_firstname" => "Steve",
      "account_credential_ffm_partner_token" => "101",
      "account_credential_ffm_usertype" => "Consumer",
      "saml_type" => "cbcffmr",
    },
    "CBCFFMr - Small Terrellpab" => {
      "client" => "cbcffmr",
      "account_credential_employer_id" => "a",
      "account_credential_employee_id" => "b",
      "account_credential_ffm_lastname" => "Wolfe",
      "account_credential_ffm_consumerid" => "94914271",
      "account_credential_ffm_partner_consumerid" => "4807",
      "account_credential_ffm_firstname" => "Steve",
      "account_credential_ffm_partner_token" => "101",
      "account_credential_ffm_usertype" => "Consumer",
      "saml_type" => "cbcffmr",
    },
    "CBCFFMr - Likely Velezpab" => {
      "client" => "cbcffmr",
      "account_credential_employer_id" => "a",
      "account_credential_employee_id" => "b",
      "account_credential_ffm_lastname" => "Wolfe",
      "account_credential_ffm_consumerid" => "95312454",
      "account_credential_ffm_partner_consumerid" => "4822",
      "account_credential_ffm_firstname" => "Steve",
      "account_credential_ffm_partner_token" => "101",
      "account_credential_ffm_usertype" => "Consumer",
      "saml_type" => "cbcffmr",
    },
    "CBCFFMr - Ezra Humphreypau" => {
      "client" => "cbcffmr",
      "account_credential_employer_id" => "a",
      "account_credential_employee_id" => "b",
      "account_credential_ffm_lastname" => "Wolfe",
      "account_credential_ffm_consumerid" => "95528370",
      "account_credential_ffm_partner_consumerid" => "4797",
      "account_credential_ffm_firstname" => "Steve",
      "account_credential_ffm_partner_token" => "101",
      "account_credential_ffm_usertype" => "Consumer",
      "saml_type" => "cbcffmr",
    },
    "CBC" => {
      "client" => "cbc",
      "account_credential_employer_id" => "CH-DEV",
      "account_credential_employee_id" => "TestEE",
      "saml_type" => "brix",
    },
    "AIC" => {
      "client" => "aic",
      "account_credential_employer_id" => "CH-DEV",
      "account_credential_employee_id" => "TestEE-2",
      "saml_type" => "brix",
    },
    "AIC (ancilliary/life)" => {
      "client" => "aic",
      "account_credential_employer_id" => "AIC_ANC13",
      "account_credential_employee_id" => "9220431",
      "saml_type" => "brix",
    },
    "AultCare" => {
      "client" => "aultcare-group",
      "account_credential_employer_id" => "CH-DEV",
      "account_credential_employee_id" => "LE-Larry",
      "saml_type" => "brix",
    },
  }

  def new
    @account_credential = AccountCredential.new(params[:account_credential])
    @preset_logins = PRESET_LOGINS
    @client = params[:client]
    @last_environment = session[:last_environment]
    @last_port = session[:last_port] || 80
    @last_protocol = session[:last_protocol]
  end

  def login
    @last_environment = session[:last_environment] = params[:environment]
    @last_port = session[:last_port] = params[:port]
    @last_protocol = session[:last_protocol] = params[:protocol]

    @account_credential = AccountCredential.new(params[:account_credential])
    if params[:client_custom].empty?
      client = params[:client]
    else
      client = params[:client_custom]
    end
    if @account_credential.valid?
      @redirect_url = "#{params[:protocol]}://#{client}.#{params[:environment]}:#{params[:port]}/authentication/saml_authentication/idp_response"
      saml_xml = get_saml_xml(params[:saml_type])
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
      encoded_request = CGI.escape(enc_saml_response)
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

  # Log out
  def request_slo
    @redirect_url = 'http://cbcffmr.ch.localhost:3000/authentication/saml_authentication'
    @saml_response = Base64.encode64(slo_xml)
    render action: 'login'
  end

  private

  def inflate(string)
    zstream = Zlib::Inflate.new(-Zlib::MAX_WBITS)
    buf = zstream.inflate(string)
    zstream.finish
    zstream.close
    buf
  end

  def slo_xml()
    File.read("#{Rails.root}/config/slo.xml")
  end

  def get_saml_xml(saml_type)
    if saml_type == 'evo_one'
      evo_one_saml_xml(@account_credential)
    elsif saml_type == 'cbcffma'
      cbcffma_saml_xml(@account_credential)
    elsif saml_type == 'cbcffmr'
      cbcffmr_saml_xml(@account_credential)
    elsif saml_type == 'brix'
      saml_xml(@account_credential)
    else
      raise "Unknown SAML type"
    end
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
      gsub('REPLACE_CART_ID', account_credential.uuid).
      gsub('REPLACE_FFM_LASTNAME', account_credential.ffm_lastname).
      gsub('REPLACE_FFM_FIRSTNAME', account_credential.ffm_firstname).
      gsub('REPLACE_FFM_CONSUMERID', account_credential.ffm_consumerid).
      gsub('REPLACE_FFM_PARTNER_CONSUMERID', account_credential.ffm_partner_consumerid).
      gsub('REPLACE_FFM_PARTNER_TOKEN', account_credential.ffm_partner_token).
      gsub('REPLACE_FFM_USERTYPE', account_credential.ffm_usertype)
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
