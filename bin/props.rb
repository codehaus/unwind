
module Unwind
  class Props
    def initialize()
      @props = {}
      @prop_text = nil
    end
  
    def empty?
      @props.empty?
    end
  
    def []=(key,value)
      @props[key]=value
      @prop_text = nil
    end
  
    def [](key)
      @props[key]
    end
  
    def text()
      return @prop_text if @prop_text
      @prop_text = ''
      @props.each do |key, value|
        @prop_text += "K #{key.length}\n"
        @prop_text += "#{key}\n"
        @prop_text += "V #{value.length}\n"
        @prop_text += "#{value}\n"
      end
      @prop_text += "PROPS-END\n"
      @prop_text
    end
  end
end
