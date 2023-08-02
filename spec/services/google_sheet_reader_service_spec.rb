# frozen_string_literal: true

require 'rails_helper'
require 'matrix'

RSpec.describe GoogleSheetReaderService do
  subject(:service) { described_class.new(gdrive_session, sheet_key) }

  WorkSheets = Struct.new(:worksheets)

  module MMatrix
    def num_rows
      3
    end

    def num_cols
      2
    end
  end

  Matrix.class_eval { include MMatrix }

  GoogleDriveSession = Struct.new(:arg) do
    def spreadsheet_by_key(_arg)
      m = Matrix[
        [nil, nil],
        %w[header header],
        [nil, 'pw1'],
        [nil, 'pw2']
      ]

      WorkSheets.new([m])
    end
  end

  let(:gdrive_session) { GoogleDriveSession.new(sheet_key) }
  let(:sheet_key) { Faker::Config.random.seed.to_s }

  describe '#initialize' do
    context 'when gdrive_session is nil' do
      let(:gdrive_session) { nil }

      it { expect { service }.to raise_error ArgumentError }
    end

    context 'when gdrive_session is invalid' do
      let(:gdrive_session) { 'abc' }

      it { expect { service }.to raise_error ArgumentError }
    end

    context 'when sheet_key is nil' do
      let(:sheet_key) { nil }

      it { expect { service }.to raise_error ArgumentError }
    end

    context 'when sheet_key is not a string' do
      let(:sheet_key) { 123 }

      it { expect { service }.to raise_error ArgumentError }
    end
  end

  describe '#read' do
    it { expect(service).to respond_to(:read) }

    it { expect(service.read).to contain_exactly('pw1', 'pw2') }
  end
end
