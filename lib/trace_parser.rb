module TraceParser
  VERSION = '1.0.2'

  ENCODERS = {
    gzip: {ext:"gz", encoder:"/usr/bin/gzip"},
    lzma: {ext:"lz", encoder:"/usr/bin/lzma"},
  }

  autoload :Ext,      "trace_parser/ext"
  autoload :Reporter, "trace_parser/reporter"

  class << self
    def encoder=(enc)
      @encoder = ENCODERS[enc] or raise
    end
    def encoder
      @encoder ||= ENCODERS[:gzip]
    end

    def trace(&block)
      start
      begin
        block.call
      ensure
        stop
      end
    end

    def trace_proc
      self.method(:trace).to_proc
    end

    def start
      open
      set_trace_func ::TraceParser::Ext.method(:callback_function).to_proc
      TraceParser::Ext.enable(@io.fileno)
    end

    def stop
      TraceParser::Ext.disable
      close
    end

    def log_filename
      @log_filename ||= "trace.log.#{self.encoder[:ext]}"
    end
    attr_writer :log_filename

  private

    def open
      @io and raise
      (in2, out2) = IO.pipe
      out1 = File.open(log_filename, "a")
      pid = Kernel::spawn(self.encoder[:encoder], "-c", in:in2, out:out1)
      out1.close
      in2.close
      @proc = Process.detach(pid)
      @io = out2
    end

    def close
      @proc.join
      @io = nil
    end
  end

end
