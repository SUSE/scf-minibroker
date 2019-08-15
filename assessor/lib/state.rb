
def state
  # Memoized
  unless @state
    # Look for state only in incremental mode. Do not fail if missing,
    # just fall back to regular mode, starting with empty state.
    if @incremental && File.exists?(statepath)
      @state = YAML.load_file(statepath)
    else
      @state = {}
    end
    # Schema:
    # - state[<engine>][<version>]['works']	:: boolean
    # - state[<engine>][<version>]['app']	:: string
    #
    # version is chart version  (`version`)
    # app     is engine version (`appVersion`)
    @state.default_proc = proc { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = Hash.new } }
  end
  @state
end

def state_save(engine, enginev, chartv, success)
  state[engine][chartv] = {
    'app'   => enginev,
    'works' => success,
  }
  File.write(statepath, @state.to_yaml)
end

def archive_save(engine, chartv)
  dst = File.join(archive_saved, "#{engine}-#{chartv}.tgz")
  FileUtils.mkdir_p(archive_saved)
  FileUtils.cp(archive_patched, dst)
end

def regenerate_working_index
  # Extract the chart blocks for all working charts from the master,
  # patch the archive location to refer to the internal dev helm
  # repository used by the brain tests, and save to a file.
  working = {}
  engines.each do |engine|
    working[engine] = []
    master_index[engine].each do |chart|
      chartv = chart['version']
      next unless state[engine][chartv] && state[engine][chartv]['works']
      new = chart.dup
      new['created'] = fixed_time
      new['urls'] = "#{mbbt_repository}/#{engine}-#{chartv}.tgz"
      working[engine] << new
    end
  end
  File.write(working_saved, working.to_yaml)
end
