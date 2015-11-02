require 'spec_helper'

describe Lacerda::Reporters::Multi do
  context "dispatch to each registered reporter" do
    methods = Lacerda::Reporter.instance_methods - Object.instance_methods
    methods.each do |m|
      it ":#{m}" do
        reporters = [
          Lacerda::Reporters::Stdout.new(verbose: false),
          Lacerda::Reporters::RSpec.new()
        ]
        multi = Lacerda::Reporters::Multi.new(reporters)
        reporters.each do |r|
          expect(r).to receive(:send).once.with(m, :some, :args).and_return :ok
        end
        multi.send(m, :some, :args)
      end
    end

  end
end
