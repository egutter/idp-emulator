require "base64"
require "zlib"
require "cgi"

class SamlController < ApplicationController

  ASSERTION = "urn:oasis:names:tc:SAML:2.0:assertion"
  PROTOCOL  = "urn:oasis:names:tc:SAML:2.0:protocol"

	def signon
		encoded_saml = params[:SAMLRequest]
    decoded_saml = inflate(Base64.decode64(encoded_saml))

    redirect_url = Nokogiri.XML(decoded_saml).at_xpath('//samlp:AuthnRequest').attribute('AssertionConsumerServiceURL').value
    redirect_url << "?SAMLResponse=#{CGI.escape(Base64.encode64(saml_xml))}"
    redirect_to redirect_url

    #raise "#{decoded_saml}"
    #render :text => redirect_url
	end

	def show
		render :text => saml_xml.html_safe
	end

	private

  def inflate(string)
    zstream = Zlib::Inflate.new(-Zlib::MAX_WBITS)
    buf = zstream.inflate(string)
    zstream.finish
    zstream.close
    buf
  end
	def saml_xml
    account_credential = AccountCredential.instance
		File.read("#{Rails.root}/config/saml_response.xml").gsub('REPLACE_EMPLOYER_ID', account_credential.employer_id).gsub('REPLACE_EMPLOYEE_ID', account_credential.employee_id)
	end

end
