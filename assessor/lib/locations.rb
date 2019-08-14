
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
  @wsaved ||= File.join(archive_saved, 'index.yaml')
end

def archive_saved
  @asaved ||= File.join(@workdir, 'ok')
end

def archive_orig
  @aunpatched ||= File.join(@workdir, 'archive-orig.tgz')
end

def archive_patched
  @apatched ||= File.join(@workdir, 'archive-patched.tgz')
end

def manifest
  @manifest ||= File.join(appdir, "manifest.yml")
end

def chart_index
  @chartindex ||= File.join(appdir, "index.yaml")
end

def archive_app
  @aapp ||= File.join(appdir, chart_in_app)
end

def domain
  @domain, _, _ = capture "kubectl get pods -o json --namespace \"#{@namespace}\" api-group-0 | jq -r '.spec.containers[0].env[] | select(.name == \"DOMAIN\").value'" unless @domain
  @domain
end

def tester
  @brain ||= File.join(@scfdir, "make/tests")
end

def appsrc
  @appsrc ||= File.join(@scfdir, "src/scf-release/src/acceptance-tests-brain/test-resources/node-env")
end

def helm_repo
  @helmrepo ||= "http://#{helm_app}.#{domain}"
end

def target
  @target ||= "https://api.#{domain}"
end

def chart_ref
  @chartref ||= "#{helm_repo}/#{chart_in_app}"
end
