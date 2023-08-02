# frozen_string_literal: true

class GoogleSheetReaderService
  attr_reader :session, :sheet_key

  def initialize(session, sheet_key, col = 1)
    raise ArgumentError unless valid_sheet_key?(sheet_key)
    raise ArgumentError unless valid_session?(session)

    @session = session
    @sheet_key = sheet_key
    @col = col
  end

  def read
    list = []
    ws = session.spreadsheet_by_key(@sheet_key).worksheets[0]

    (2..ws.num_rows).each do |row|
      list << ws[row, @col]
    end

    list
  end

  private

  def valid_sheet_key?(sheet_key)
    sheet_key.present? && (sheet_key.is_a? String)
  end

  def valid_session?(session)
    session.respond_to?(:spreadsheet_by_key)
  end
end
