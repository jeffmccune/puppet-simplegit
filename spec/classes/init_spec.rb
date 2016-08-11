require 'spec_helper'
describe 'simplegit' do
  context 'with default values for all parameters' do
    it { should contain_class('simplegit') }
  end
end
