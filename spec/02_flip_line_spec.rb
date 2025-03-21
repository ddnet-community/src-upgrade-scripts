# frozen_string_literal: true

require_relative '../sql_true_for_success'

WARN_TEXT = " // TODO: check this bool manually ^^\n#warning \"sql bool needs attention\""

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

  context 'pass on return of sql method' do
    it 'should not flip the call because its return is flipped' do
      known_sql_method = "return pSqlServer->ExecuteUpdate(&NumInserted, pError, ErrorSize);"
      expect(flip_line(known_sql_method)).to eq(known_sql_method)

      known_sql_method = "return pSqlServer->ExecuteUpdate(&NumDeleted, pError, ErrorSize);"
      expect(flip_line(known_sql_method)).to eq(known_sql_method)

      known_sql_method = "return pSqlServer->Step(&End, pError, ErrorSize);"
      expect(flip_line(known_sql_method)).to eq(known_sql_method)
    end
  end

  context 'return custom 0XF method' do
    it 'should not flip the call because its return is flipped' do
      custom_0xf_sql_method = 'return pSqlServer->ExecuteUpdate("DELETE FROM punishments WHERE end_date < CURRENT_TIMESTAMP", pError, ErrorSize);'
      expect(flip_line(custom_0xf_sql_method)).to eq(custom_0xf_sql_method)
    end
  end

  context 'should warn on unknown method' do
    it 'should not flip the call because its return is flipped' do
      unknown_method = "return pSqlServer->WhatIsThis();"
      expect(flip_line(unknown_method)).to eq(unknown_method + WARN_TEXT)
    end
  end

  context 'return complex statement' do
    it 'should add warning comment' do
      expect(flip_line("return 2 == 0;")).to eq("return 2 == 0;" + WARN_TEXT)
    end
  end
end

