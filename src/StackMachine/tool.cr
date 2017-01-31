module StackMachine

  module Tool(E)

    macro assert_type(value, type, message)
      if {{value}}.is_a? {{type}}
        {{yield}}
      else
        raise E.new {{message}}
      end
    end

  end
end
