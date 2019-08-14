
# Global option for error handling in run, capture
$opts = { errexit: true }

# ......................................................................
# Logging, and terminal cursor control
# First three commands snarfed from test utils and modified to suit
# (divert output into log file)

# Set global options.
# If a block is given, the options are only active in that block.
def set(opts={})
    if block_given?
        old_opts = $opts.dup
        $opts.merge! opts
        yield
        $opts.merge! old_opts
    else
        $opts.merge! opts
    end
end

def run(*args)
  opts = $opts.dup
  opts.merge! args.last if args.last.is_a? Hash
  _, _, status = capture(*args)
  return unless opts[:errexit]
  unless status.success?
    # Print an error at the failure site
    puts "Command exited with #{status.exitstatus}".red
    fail "Command exited with #{status.exitstatus}"
  end
end

def capture(*args)
  _print_command(*args)
  args.last.delete :errexit if args.last.is_a? Hash
  stdout, stderr, status = Open3.capture3(*args)
  log stdout
  log stderr.red
  return stdout.chomp, stderr.chomp, status
end

# Internal helper: print a command line in the log.
def _print_command(*args)
    cmd = args.dup
    cmd.shift if cmd.first.is_a? Hash
    cmd.pop if cmd.last.is_a? Hash
    log "+ #{cmd.join(" ")}".bold
    log "\n"
end
