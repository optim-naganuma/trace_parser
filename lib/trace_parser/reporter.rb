
module TraceParser
  class Reporter
    attr_reader :options
    attr_reader :params

    ID_STACK = 0
    ID_DTIME = 1
    ID_CTIME = 4

    stack = []
    TOKEN = /[\t\r\n]/

    MARKER = "-+=*"

    def initialize(params)
      @params = params
      @options = {}
      params.delete_if do | opt |
        if opt =~ /\A--(.*?)=(.*)\z/
          @options[$1.to_sym] = $2
        end
      end
    end

    def parse(io = ARGF)
      @logs = []
      stack = []

      io.each do |line|
        (time, file, line, klass, method, event) = line.split(TOKEN)

        current = [stack.size, nil, file, line, time.to_f, event]

        case event
        when "c-call", "call"
          stack.push current

        when "c-return", "return"
          if before = stack.pop
            before[ID_DTIME] = ((current[ID_CTIME] - before[ID_CTIME])*1000000).to_i
          end

        when "line"
          if before = @logs.last
            current[ID_DTIME] = ((current[ID_CTIME] - before[ID_CTIME])*1000000).to_i
          end

        end

        @logs << current

      end

      current = @logs.last
      while before = stack.pop
        before[ID_DTIME] = ((current[ID_CTIME] - before[ID_CTIME])*1000000).to_i
      end
    end

    def write_text
      max_depth = options[:max_depth].to_i if options[:max_depth]
      min_usec = options[:min_usec].to_i if options[:min_usec]

      @logs.each do | rows |
        next if max_depth && max_depth < rows[ID_STACK]
        next if min_usec && rows[ID_DTIME].to_i < min_usec

        rows[ID_STACK] = " "*rows[ID_STACK] + MARKER[rows[ID_STACK] % 4]
        puts rows.join("\t")
      end
    end

    def run
      method = params.shift
      parse
      send("write_#{method}")
    end
  end
end

