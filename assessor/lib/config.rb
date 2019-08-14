
def config
  @workdir     = File.join(@top, '_work/assessor')
  @namespace   = "cf"
  @auth        = "changeme"
  @incremental = false
  @scfdir      = nil

  OptionParser.new do |opts|
    opts.banner = "Usage: assess-minibroker-charts [options]"
    opts.on("-wPATH", "--work-dir=PATH", "Set work directory for state and transients") do |v|
      @workdir = File.absolute_path(v.to_s)
    end
    opts.on("-sPATH", "--scf-dir=PATH", "Set SCF source directory") do |v|
      @scfdir = File.absolute_path(v.to_s)
    end
    opts.on("-nNAME", "--namespace=NAME", "Set SCF namespace") do |v|
      @namespace = v.to_s
    end
    opts.on("-pPASS", "--password=PASS", "Set cluster admin password") do |v|
      @auth = v.to_s
    end
    opts.on("-i", "--incremental", "Activate incremental mode") do |v|
      @incremental = true
    end
  end.parse!

  puts "Configuration".cyan
  puts "  - Namespace: #{@namespace.blue}"
  puts "  - Password:  #{@auth.blue}"
  puts "  - Mode:      #{mode.blue}"
  puts "  - Top:       #{@top.blue}"
  puts "  - Work dir:  #{@workdir.blue}"
  puts "  - SCF dir:   #{@scfdir.blue}"
  puts "  - Domain:    #{domain.blue}"

  FileUtils.mkdir_p(@workdir)
end

def mode
  if @incremental
    "incremental, keeping previous data"
  else
    "fresh, clearing previous data"
  end
end

def engines
  # Add new engines here. May also have to change the test case
  # selection if the name of the test case in the brain tests deviates
  # from the name of the database engine. We assume a name of the form
  # `<nnn>_minibroker_<engine>_test`.
  [
    'mariadb',
    'mongodb',
    'postgresql',
    'redis'
  ]
end
