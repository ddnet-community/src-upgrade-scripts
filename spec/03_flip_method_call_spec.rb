# frozen_string_literal: true

require_relative '../sql_true_for_success'

describe '#flip_method_call' do
  context 'in true if statement' do
    it 'should flip naked call' do
      expect(flip_method_call("if(foo())", "foo")).to eq("if(!foo())")
    end

    it 'should flip namespace call' do
      expect(flip_method_call("if(bar::foo())", "foo")).to eq("if(!bar::foo())")
    end

    it 'should flip member call' do
      expect(flip_method_call("if(bar.foo())", "foo")).to eq("if(!bar.foo())")
    end

    it 'should flip pointer call' do
      expect(flip_method_call("if(bar->foo())", "foo")).to eq("if(!bar->foo())")
    end

    it 'should not flip substring match' do
      expect(flip_method_call("if(barfoo())", "foo")).to eq("if(barfoo())")
    end
  end
end

