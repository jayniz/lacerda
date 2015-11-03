require 'lib/lacerda'
require 'lib/lacerda/reporters/rspec'

module Lacerda
  module RspecIntegration
    def self.validate_infrastructure(infrastructure)
      reporter = Lacerda::Reporters::Rspec.new
      Rspec.describe "Lacerda infrastructure contracts validation" do
        infrastructure.contracts_fulfilled?(reporter)
      end
    end
  end
end

# config.after(:suite) do
#   
#   example_group = RSpec.describe('Lacerda infrastructure contract validation')
#   example = example_group.example('must be 100%'){
#     expect( SimpleCov.result.covered_percent ).to eq 100
#   }
#   example_group.run
# 
#   passed = example.execution_result.status == :passed
#   if passed or ENV['IGNORE_LOW_COVERAGE']
#     RSpec.configuration.reporter.example_passed example
#   else
#     RSpec.configuration.reporter.example_failed example
#   end
# end
