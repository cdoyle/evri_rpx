require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe Evri::RPX::Session do
  before(:all) do
    @session = Evri::RPX::Session.new('fake_api_key')
  end

  describe "api_key" do
    it "should return the current API key" do
      @session.api_key.should == 'fake_api_key'
    end
  end

  describe "auth_info" do
    after(:each) do
      FakeWeb.clean_registry
    end

    it "should raise an APICallError if RPX returns an error message" do
      FakeWeb.register_uri(:get,
                           'http://rpxnow.com:443/api/v2/auth_info',
                           :file => fixture_path('session/normal_error.json'),
                           :status => ['400', 'Bad Request'])
      lambda {
        @session.auth_info('errortoken')
      }.should raise_error(Evri::RPX::Session::APICallError)
    end

    it "should raise ServiceUnavailableError if the service is not available" do
      FakeWeb.register_uri(:get,
                           'http://rpxnow.com:443/api/v2/auth_info',
                           :file => fixture_path('session/service_down_error.json'),
                           :status => ['404', 'Not Found'])
      lambda {
        @session.auth_info('errortoken')
      }.should raise_error(Evri::RPX::Session::ServiceUnavailableError)
    end

    it "should return a User object for a mapping" do
      FakeWeb.register_uri(:get,
                           'http://rpxnow.com:443/api/v2/auth_info',
                           :file => fixture_path('user/dbalatero_gmail.json'))

      result = @session.auth_info('mytoken')
      result.should be_a_kind_of(Evri::RPX::User)
    end
  end

  describe "map" do
    before(:each) do
      FakeWeb.register_uri(:get,
                           'http://rpxnow.com:443/api/v2/map',
                           :file => fixture_path('session/map.json'))
    end

    it "should take in a User object as the second parameter" do
      user = mock('user')
      user.should_receive(:identifier).and_return('http://www.facebook.com/dbalatero')

      result = @session.map(user, 50)
      result.should be_true
    end

    it "should take in a identifier string as the second parameter" do
      result = @session.map('http://www.facebook.com/dbalatero', 50)
      result.should be_true
    end
  end

  describe "mappings" do
    it "should return a Mappings object" do
      FakeWeb.register_uri(:get,
                           'http://rpxnow.com:443/api/v2/mappings',
                           :file => fixture_path('mappings/identifiers.json'))

      result = @session.mappings('dbalatero')
      result.should be_a_kind_of(Evri::RPX::Mappings)
      result.identifiers.should_not be_empty
    end

    it "should take a User object in" do
      FakeWeb.register_uri(:get,
                           'http://rpxnow.com:443/api/v2/mappings',
                           :file => fixture_path('mappings/identifiers.json'))
      user = mock('user')
      user.should_receive(:primary_key).and_return('dbalatero')

      result = @session.mappings(user)
      result.should be_a_kind_of(Evri::RPX::Mappings)
      result.identifiers.should_not be_empty
    end
  end

  describe "unmap" do
    before(:each) do
      FakeWeb.register_uri(:get,
                           'http://rpxnow.com:443/api/v2/unmap',
                           :file => fixture_path('session/unmap.json'))
    end

    it "should take a string as the identifier" do
      result = @session.unmap('http://www.facebook.com/dbalatero', 50)
      result.should be_true
    end

    it "should take a User as the identifier" do
      user = mock('user')
      user.should_receive(:identifier).and_return('http://www.facebook.com/dbalatero')

      result = @session.unmap(user, 50)
      result.should be_true
    end
  end
end
