require 'spec_helper_acceptance'

describe 'keycloak_realm:', if: RSpec.configuration.keycloak_full do
  context 'creates realm' do
    it 'runs successfully' do
      pp = <<-EOS
      include mysql::server
      class { 'keycloak':
        datasource_driver => 'mysql',
      }
      keycloak_realm { 'test':
        ensure => 'present',
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'has created a realm' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get realms/test' do
        data = JSON.parse(stdout)
        expect(data['id']).to eq('test')
      end
    end

    it 'has left default-client-scopes' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get realms/test/default-default-client-scopes' do
        data = JSON.parse(stdout)
        names = data.map { |d| d['name'] }.sort
        expect(names).to include('email')
        expect(names).to include('profile')
        expect(names).to include('role_list')
      end
    end

    it 'has left optional-client-scopes' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get realms/test/default-optional-client-scopes' do
        data = JSON.parse(stdout)
        names = data.map { |d| d['name'] }.sort
        expect(names).to include('address')
        expect(names).to include('offline_access')
        expect(names).to include('phone')
      end
    end

    it 'has default events config' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get events/config -r test' do
        data = JSON.parse(stdout)
        expect(data['eventsEnabled']).to eq(false)
        expect(data['eventsExpiration']).to be_nil
        expect(data['eventsListeners']).to eq(['jboss-logging'])
        expect(data['adminEventsEnabled']).to eq(false)
        expect(data['adminEventsDetailsEnabled']).to eq(false)
      end
    end
  end

  context 'updates realm' do
    it 'runs successfully' do
      pp = <<-EOS
      include mysql::server
      class { 'keycloak':
        datasource_driver => 'mysql',
      }
      keycloak_realm { 'test':
        ensure => 'present',
        remember_me => true,
        access_code_lifespan => 3600,
        access_token_lifespan => 3600,
        sso_session_idle_timeout => 3600,
        sso_session_max_lifespan => 72000,
        default_client_scopes => ['profile'],
        content_security_policy => "frame-src https://*.duosecurity.com/ 'self'; frame-src 'self'; frame-ancestors 'self'; object-src 'none';",
        events_enabled => true,
        events_expiration => 2678400,
        admin_events_enabled => true,
        admin_events_details_enabled => true,
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'has updated the realm' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get realms/test' do
        data = JSON.parse(stdout)
        expect(data['rememberMe']).to eq(true)
        expect(data['accessCodeLifespan']).to eq(3600)
        expect(data['accessTokenLifespan']).to eq(3600)
        expect(data['ssoSessionIdleTimeout']).to eq(3600)
        expect(data['ssoSessionMaxLifespan']).to eq(72_000)
        expect(data['browserSecurityHeaders']['contentSecurityPolicy']).to eq("frame-src https://*.duosecurity.com/ 'self'; frame-src 'self'; frame-ancestors 'self'; object-src 'none';")
      end
    end

    it 'has updated the realm default-client-scopes' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get realms/test/default-default-client-scopes' do
        data = JSON.parse(stdout)
        names = data.map { |d| d['name'] }
        expect(names).to eq(['profile'])
      end
    end

    it 'has updated events config' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get events/config -r test' do
        data = JSON.parse(stdout)
        expect(data['eventsEnabled']).to eq(true)
        expect(data['eventsExpiration']).to eq(2_678_400)
        expect(data['eventsListeners']).to eq(['jboss-logging'])
        expect(data['adminEventsEnabled']).to eq(true)
        expect(data['adminEventsDetailsEnabled']).to eq(true)
      end
    end
  end

  context 'creates realm with invalid browser flow' do
    it 'runs successfully' do
      pp = <<-EOS
      include mysql::server
      class { 'keycloak':
        datasource_driver => 'mysql',
      }
      keycloak_realm { 'test2':
        ensure       => 'present',
        browser_flow => 'Copy of browser',
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, expect_changes: true)
    end

    it 'has created a realm' do
      on hosts, '/opt/keycloak/bin/kcadm-wrapper.sh get realms/test2' do
        data = JSON.parse(stdout)
        expect(data['browserFlow']).to eq('browser')
      end
    end
  end
end
