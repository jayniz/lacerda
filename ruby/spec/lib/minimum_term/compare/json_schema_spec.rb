require 'spec_helper'

describe MinimumTerm::Compare::JsonSchema do
  context "comparing basic publish and consume schemas" do
    let(:consume_file) { File.expand_path("../../../../support/json_schemas/consume.schema.json", __FILE__) }

    before(:all) do
      publish_file = File.expand_path("../../../../support/json_schemas/publish.schema.json", __FILE__)
      @publish_schema = MinimumTerm::Compare::JsonSchema.new(publish_file)
    end

    describe '#contains?' do
      context "publish containing consume" do
        it "doesn't detect a difference" do
          expect(@publish_schema.contains?(consume_file)).to be_truthy
        end
      end

      context "publish NOT containing consume" do
        it "detects a wrong type" do
          expect(@publish_schema.contains?(consume_file)).to be_falsey
        end
      end
    end
  end
end