
# ......................................................................
# Engine-specific constructed values

def testcase_of(engine)
  return "_minibroker_postgres" if engine =~ /postgresql/
  "_minibroker_#{engine}"
end

def patch_of(engine)
  File.join(@top, "assessor/patches", "#{engine}.patch")
end

# ......................................................................
# Various (semi)constant values, mostly paths and the like

def mbbt_repository
  "https://minibroker-helm-charts.s3.amazonaws.com/kubernetes-charts"
end

def fixed_time
  "2018-07-30T17:55:01.330815339Z"
end

def stable
  "https://kubernetes-charts.storage.googleapis.com"
end

def helm_app
  "chart-under-test"
end

def chart_in_app
  "chart.tgz"
end

def statepath
  @statepath ||= File.join(@workdir, 'results.yaml')
end

def appdir
  @appdir ||= File.join(@workdir, "charts")
end

def working_saved
  @working_saved ||= File.join(archive_saved, 'index.yaml')
end

def archive_saved
  @archive_saved ||= File.join(@workdir, 'ok')
end

def archive_orig
  @archive_orig ||= File.join(@workdir, 'archive-orig.tgz')
end

def archive_patched
  @archive_patched ||= File.join(@workdir, 'archive-patched.tgz')
end

def manifest
  @manifest ||= File.join(appdir, "manifest.yml")
end

def chart_index
  @chart_index ||= File.join(appdir, "index.yaml")
end

def archive_app
  @archive_app ||= File.join(appdir, chart_in_app)
end

def domain
  unless @domain
    pod, _, _ = capture "kubectl", "get", "pods", "-o", "yaml", "--namespace", @namespace, "api-group-0"
    @domain = YAML.load(pod)['spec']['containers'][0]['env'].select { |ev| ev['name'] == "DOMAIN" }.first['value']
  end
  @domain
end

def tester
  @tester ||= File.join(@scfdir, "make/tests")
end

def appsrc
  @appsrc ||= File.join(@scfdir, "src/scf-release/src/acceptance-tests-brain/test-resources/node-env")
end

def helm_repo
  @helm_repo ||= "http://#{helm_app}.#{domain}"
end

def target
  @target ||= "https://api.#{domain}"
end

def chart_ref
  @chart_ref ||= "#{helm_repo}/#{chart_in_app}"
end
