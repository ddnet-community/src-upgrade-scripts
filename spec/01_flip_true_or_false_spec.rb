# frozen_string_literal: true

require_relative '../sql_true_for_success'

describe '#flip_true_or_false' do
  context 'true' do
    it 'should flip to false' do
      expect(flip_true_or_false("true", "true", "false")).to eq("false")
    end
  end

  context 'false' do
    it 'should flip to true' do
      expect(flip_true_or_false("false", "true", "false")).to eq("true")
    end
  end

  context 'return false;' do
    it 'should flip to true' do
      expect(flip_true_or_false("return false;", "true", "false")).to eq("return true;")
    end
  end

  context 'return true;' do
    it 'should flip to false' do
      expect(flip_true_or_false("return true;", "true", "false")).to eq("return false;")
    end
  end
end

