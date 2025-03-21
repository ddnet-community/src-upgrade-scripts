# frozen_string_literal: true

require_relative '../sql_true_for_success'

describe '#flip_line' do
  context 'return true;' do
    it 'should flip to false' do
      expect(flip_line("return true;")).to eq("return false;")
    end
  end

  context 'return false;' do
    it 'should flip to true' do
      expect(flip_line("return false;")).to eq("return true;")
    end


    it 'should keep leading spaces' do
      expect(flip_line("   return false;")).to eq("   return true;")
    end
  end

  context 'return false with comment' do
    it 'should flip to true and keep the comment' do
      expect(flip_line("return false; // uwu")).to eq("return true; // uwu")
    end
  end

  context 'return complex statement' do
    it 'should add warning comment' do
      expect(flip_line("return 2 == 0;")).to eq("return 2 == 0; // TODO: check this bool manually ^^\n#warning \"sql bool needs attention\"")
    end
  end
end

