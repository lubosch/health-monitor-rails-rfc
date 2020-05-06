# frozen_string_literal: true

require 'spec_helper'

describe 'Health Monitor' do
  context 'when check is ok' do
    it 'renders html' do
      visit '/health'
      expect(page).to have_css('span', class: 'name', text: 'Database')
      expect(page).to have_css('span', class: 'state', text: 'pass')
    end
  end

  context 'when check failed' do
    before do
      Providers.stub_database_failure
    end
    it 'renders html' do
      visit '/health'
      expect(page).to have_css('span', class: 'name', text: 'Database')
      expect(page).to have_css('span', class: 'state', text: 'fail')
      expect(page).to have_css('div', class: 'message', text: 'my db exception')
    end
  end
end
