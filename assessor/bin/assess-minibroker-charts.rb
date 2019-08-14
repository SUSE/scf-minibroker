#!/usr/bin/env ruby
##
# The purpose of this script is to assess which of the publicly
# available charts for the databases supported by minibroker will work
# with SCF.

# Configuration
# - Fixed location: `stable` helm repository
# - Configurable:   work directory for state
# - Configurable:   scf source directory
# - Configurable:   scf namespace
# - Configurable:   Cluster Admin Password
# - Configurable:   Operation mode (full, incremental)

require 'fileutils'
require 'net/http'
require 'open3'
require 'optparse'
require 'uri'
require 'yaml'

require_relative "../lib/colors.rb"
require_relative "../lib/config.rb"
require_relative "../lib/helmrepo.rb"
require_relative "../lib/locations.rb"
require_relative "../lib/log.rb"
require_relative "../lib/spawn.rb"
require_relative "../lib/state.rb"
require_relative "../lib/terminal.rb"
require_relative "../lib/testcore.rb"

@top = File.dirname(File.dirname(File.dirname(File.absolute_path(__FILE__))))

def main
  config
  base_statistics

  @assessed = 0
  @skipped = 0
  state

  engines.each do |engine|
    master_index[engine].each do |chart|
      enginev        = chart['appVersion']
      chartv         = chart['version']
      chart_location = chart['urls'].first

      # We are ignoring all the entries for which we do not have the
      # engine version. Because that is the plan id later, therefore
      # required.
      next unless enginev
      next if skip_chart?(engine, enginev, chartv)

      assess_chart(chart, engine, enginev, chartv, chart_location)
    end
  end

  rewind_line
  puts "#{"Skipped".cyan}:  #{@skipped}"  if @skipped
  puts "#{"Assessed".cyan}: #{@assessed}" if @assessed
end

def master_index
  unless @master
    puts "#{"Retrieving".cyan} master index ..."
    @master = helm_index(stable)['entries']
  end
  @master
end

def helm_index(location)
    uri = URI.parse(location + "/index.yaml")
    res = Net::HTTP.get_response uri

    # Debugging, save index data.
    File.write(File.join(@workdir, 'index-location.txt'), uri)
    File.write(File.join(@workdir, 'index.yaml'), res.body)

    YAML.load(res.body)
end

def base_statistics
  engines.each do |engine|
    # Debugging. Save per-engine indices.
    File.write(File.join(@workdir, "e-#{engine}.yaml"), master_index[engine].to_yaml)

    # We are ignoring all the entries for which we do not have the
    # engine version. Because that is the plan id later, therefore
    # required.

    count = master_index[engine].select {|c| c['appVersion']}.length
    puts "#{"Extracting".cyan} engine #{engine.blue}: #{count.to_s.cyan} charts"
  end
end

def skip_chart?(engine, enginev, chartv)
  return false unless @incremental && state[engine][chartv]
  @skipped += 1
  rewind_line
  write "Skipping #{engine} #{enginev} #{chartv}"
  # delay to actually see the output ?
  true
end

def assess_chart (chart, engine, enginev, chartv, chart_location)
  log_start(engine, enginev, chartv)

  rewind_line
  write "  - #{engine.blue} #{enginev.blue}, chart #{chartv.blue} ..."
  @success = false

  begin
    separator " helm repo setup ..." do
      @the_repo = helm_repo_setup(chart, engine, chart_location)

      if @the_repo
        " helm repo #{"up".green},"
      else
        state_save(engine, enginev, chartv, false)
        " helm repo #{"start failed".repo}, likely a patch failure"
      end
    end

    return "" unless @the_repo

    begin
      separator " testing ..." do
        @success = do_test(@the_repo, engine)
        state_save(engine, enginev, chartv, @success)

        if @success
          " testing #{"OK".green},"
        else
          " testing #{"FAIL".red},"
        end
      end
    ensure
      # clear leftovers, service & broker parts, ignoring errors.
      separator " post assessment, clearing service & broker state ..." do
        test_clear(engine)
        ""
      end
    end
    
  ensure
    @assessed += 1
    archive_save(engine, chartv) if @success
    regenerate_working_index if @success

    separator " helm repo shutdown ..." do
      helm_repo_shutdown
      " helm repo #{"down".blue},"
    end

    puts " done"
    log_done
  end
end

# ......................................................................
main
