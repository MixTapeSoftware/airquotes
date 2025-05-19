module QuoteCompareHelpers
  def needs_line_items_partial?(value)
    array_of_line_items?(value) || hash_containing_line_items?(value)
  end

  def array_of_line_items?(value)
    value.is_a?(Array) &&
    value.first.is_a?(Hash) &&
    value.first.key?("amount") &&
    value.first.key?("description")
  end

  def hash_containing_line_items?(value)
    value.is_a?(Hash) &&
    value.values.any? do |v|
      v.is_a?(Array) &&
      v.first.is_a?(Hash) &&
      v.first.key?("amount") &&
      v.first.key?("description")
    end
  end
end
