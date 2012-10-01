require 'test_helper'

class AccountCredentialsControllerTest < ActionController::TestCase
  setup do
    @account_credential = account_credentials(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:account_credentials)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create account_credential" do
    assert_difference('AccountCredential.count') do
      post :create, :account_credential => @account_credential.attributes
    end

    assert_redirected_to account_credential_path(assigns(:account_credential))
  end

  test "should show account_credential" do
    get :show, :id => @account_credential.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @account_credential.to_param
    assert_response :success
  end

  test "should update account_credential" do
    put :update, :id => @account_credential.to_param, :account_credential => @account_credential.attributes
    assert_redirected_to account_credential_path(assigns(:account_credential))
  end

  test "should destroy account_credential" do
    assert_difference('AccountCredential.count', -1) do
      delete :destroy, :id => @account_credential.to_param
    end

    assert_redirected_to account_credentials_path
  end
end
