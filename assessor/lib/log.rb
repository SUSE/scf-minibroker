
def separator(text)
  sepline = '_' * 60 + " #{text} ___"
  log "\n#{sepline.magenta}\n"
  write text
  message = yield
  left text.length
  eeol
  write message
end

def log_start(engine, enginev, chartv)
  enginedir = File.join(@workdir, engine)
  FileUtils.mkdir_p(enginedir)
  @log = File.open(File.join(enginedir, "#{enginev}-#{chartv}.log"),
                   File::CREAT|File::TRUNC|File::WRONLY|File::APPEND)
  log "Tracking operation ..."
end

def log(text)
  return "" unless @log
  @log.puts text
  @log.flush
end

def log_done
  @log = nil
end
