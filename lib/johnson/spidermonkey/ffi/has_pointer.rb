module Johnson
  module SpiderMonkey

    module HasPointer

      def to_ptr
        if @ptr && !@ptr.null?
          @ptr
        end
      end

    end

  end
end
