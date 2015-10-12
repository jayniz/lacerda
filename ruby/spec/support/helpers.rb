def contracts_dir
  File.join(File.dirname(__FILE__), "contracts")
end

RSpec.configure do |c|
  c.before(:suite) do
    path = File.join(contracts_dir, "service_test")
    puts "Loading test Infrastructure from #{path}"
    $test_infrastructure = MinimumTerm::Infrastructure.new(path)
    $test_infrastructure.convert_all!
  end
end
