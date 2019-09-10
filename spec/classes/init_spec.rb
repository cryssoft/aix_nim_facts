require 'spec_helper'
describe 'aix_nim_facts' do
  context 'with default values for all parameters' do
    it { should contain_class('aix_nim_facts') }
  end
end
