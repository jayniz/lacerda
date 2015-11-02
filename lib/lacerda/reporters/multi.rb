require 'lacerda/reporter'

module Lacerda
  module Reporters
    class Multi < Lacerda::Reporter
      def initialize(*reporters)
        @reporters = []
        [reporters].flatten.each do |r|
          @reporters << Lacerda.validate_reporter(r)
        end
      end
  
       methods = Lacerda::Reporter.instance_methods - Object.instance_methods
       methods.each do |method|
         define_method method do |*args|
           send_args = [method, args].flatten
           @reporters.each do |r|
             r.send(*send_args)
           end
         end
       end
    end
  end
end

#methods = Lacerda::Reporter.instance_methods - Object.instance_methods
#methods.each do |method|
#  Lacerda::Reporters::Multi.send(:define_method, method) do |*args|
#    send_args = [method, args].flatten.compact
#    @reporters.each do |r|
#      r.send(*[method, args].flatten)
#    end
#  end
#end
