
def helm_repo_shutdown
  # After a test we shut the local helm repository down again. We ignore failures.
  set errexit: false do
    run "cf", "delete",       "-f", helm_app
    run "cf", "delete-space", "-f", "mb-charting"
    run "cf", "delete-org",   "-f", "mb-charting"
  end
  FileUtils.remove_dir(appdir, force = true)
end

def helm_repo_setup(chart, engine, chartlocation)
  # Assemble and run node-env app serving the helm repository.
  # I. Copy original app into fresh directory
  FileUtils.remove_dir(appdir, force = true)
  FileUtils.cp_r(appsrc, appdir)

  # II. Change app name to something more suitable
  m = YAML.load_file (manifest)
  m['applications'][0]['name'] = helm_app
  File.write(manifest, m.to_yaml)

  # III. Write remote helm chart to local file
  get_engine_chart(chartlocation)

  # IV. Patch local chart archive. Stop on failure
  return "" unless sucessfully_patched_chart(engine)

  # V. Place index (*) and patched chart.
  #    (*) With proper chart archive reference
  File.write(chart_index, make_index_yaml(chart, engine, chart_ref))
  FileUtils.cp(archive_patched, archive_app)

  # VI. Start repository (push app)

  run "cf", "api", "--skip-ssl-validation", target
  run "cf", "auth", "admin", @auth
  run "cf create-org   mb-charting"
  run "cf target    -o mb-charting"
  run "cf create-space mb-charting"
  run "cf target    -o mb-charting"
  run "cf enable-feature-flag diego_docker"

  FileUtils.cd(appdir) do
    run "cf", "push", "-n", helm_app
  end

  # Report location
  helm_repo
end

def get_engine_chart(chartlocation)
    uri = URI.parse (chartlocation)
    res = Net::HTTP.get_response uri
    File.write(archive_orig, res.body)
end

def sucessfully_patched_chart(engine)
  patch = patch_of(engine)
  if File.exists?(patch)
    # Patch required - setup, unpack, modify, repack, cleanup
    # setup
    tmp = File.join(@workdir, "tmp")
    FileUtils.remove_dir(tmp, force = true)
    FileUtils.mkdir_p(tmp)

    # unpack
    run "tar", "xfz", archive_orig, "-C", tmp

    # modify
    FileUtils.cd (File.join(tmp, engine, "templates")) do
      @patch_stdout, _, @patch_status = capture "patch", "--verbose", "-i", patch
    end
    unless @patch_status.success?
      # Check for `Reversed` and accept that, else fail
      unless @patch_stdout =~ /Reversed/
        return false
      end
    end

    # repack
    run "tar", "cfz", archive_patched, "-C", tmp, engine

    # cleanup
    FileUtils.remove_dir(tmp)
  else
    # No patch, just copy, cannot fail
    FileUtils.cp(archive_orig, archive_patched)
  end
  true
end

def make_index_yaml (chart, engine, newloc)
  index = {
    'apiVersion' => 'v1',
    'entries'    => {
      engine => []
    },
  }
  index['entries'][engine] << chart.dup
  # Relocate
  index['entries'][engine][0]['urls'] = [ newloc ]
  # Go does not parse the timestamp format emitted by ruby.
  # See if using a string is ok.
  index['entries'][engine][0]['created'] = fixed_time
  index.to_yaml
end
