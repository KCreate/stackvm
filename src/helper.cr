class String
  # Indent a string with *prefix*, *amount* times
  #
  # ```
  # "hello".indent(2, "$")
  # # => "$$hello"
  # ```
  def indent(amount : Int32, prefix : String)
    self.each_line.map { |line|
      (prefix * amount) + line
    }.join "\n"
  end
end

# Includes all constants inside an enum into the current
# scope.
macro include_enum(const)
  {% for name in const.resolve.constants %}
    {{name}} = {{const}}::{{name}}
  {% end %}
end
