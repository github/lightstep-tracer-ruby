require 'spec_helper'

describe 'LightStep::Scope' do
  let(:manager) { instance_spy(LightStep::ScopeManager) }

  describe '#span' do
    it 'should return the scoped span' do
      expected = instance_spy(LightStep::Span)
      scope = LightStep::Scope.new(manager: manager, span: expected)
      expect(scope.span).to eq(expected)
    end
  end

  describe '#close' do
    it 'should close the scope' do
      scope = LightStep::Scope.new(manager: manager, span: instance_spy(LightStep::Span))
      expect { scope.close }.not_to raise_error
      expect { scope.close }.to raise_error(LightStep::Error, 'already closed')
    end

    it 'should finish the span' do
      span = instance_spy(LightStep::Span)
      scope = LightStep::Scope.new(manager: manager, span: span)
      expect(span).to receive(:finish)
      scope.close
    end

    context 'when the scope should not finish on close' do
      let(:span) { instance_spy(LightStep::Span) }
      let(:scope) { LightStep::Scope.new(manager: manager, span: span, finish_on_close: false) }

      it 'should not close the scope' do
        expect(span).not_to receive(:finish)
        scope.close
      end
    end
  end
end
