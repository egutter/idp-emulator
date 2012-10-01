class AccountCredentialsController < ApplicationController
  # GET /account_credentials
  # GET /account_credentials.xml
  def index
    @account_credentials = AccountCredential.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @account_credentials }
    end
  end

  # GET /account_credentials/1
  # GET /account_credentials/1.xml
  def show
    @account_credential = AccountCredential.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @account_credential }
    end
  end

  # GET /account_credentials/new
  # GET /account_credentials/new.xml
  def new
    @account_credential = AccountCredential.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @account_credential }
    end
  end

  # GET /account_credentials/1/edit
  def edit
    @account_credential = AccountCredential.find(params[:id])
  end

  # POST /account_credentials
  # POST /account_credentials.xml
  def create
    @account_credential = AccountCredential.new(params[:account_credential])

    respond_to do |format|
      if @account_credential.save
        format.html { redirect_to(@account_credential, :notice => 'Account credential was successfully created.') }
        format.xml  { render :xml => @account_credential, :status => :created, :location => @account_credential }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @account_credential.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /account_credentials/1
  # PUT /account_credentials/1.xml
  def update
    @account_credential = AccountCredential.find(params[:id])

    respond_to do |format|
      if @account_credential.update_attributes(params[:account_credential])
        format.html { redirect_to(@account_credential, :notice => 'Account credential was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @account_credential.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /account_credentials/1
  # DELETE /account_credentials/1.xml
  def destroy
    @account_credential = AccountCredential.find(params[:id])
    @account_credential.destroy

    respond_to do |format|
      format.html { redirect_to(account_credentials_url) }
      format.xml  { head :ok }
    end
  end
end
