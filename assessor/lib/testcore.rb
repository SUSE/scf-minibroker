
def test_clear(engine)
  set errexit: false do
    run "cf marketplace"
    stdout, _, _ = capture "cf service-brokers"
    matches = stdout.match(/(minibroker-\S*)/)
    if matches
      broker = matches[1]
      run "cf", "purge-service-offering", "-f", engine
      run "cf", "delete-service-broker",  "-f", broker
    end
  end
end

def do_test(the_repo, engine)
  # make/tests has to be run from the scf top directory or inside, to
  # be able to find its include files. Running from anywhere else and
  # GIT_ROOT is not computed correctly.
  FileUtils.cd(@scfdir) do
    _, _, @teststatus = capture tester, "acceptance-tests-brain",
	                        "env.INCLUDE=#{testcase_of(engine)}",
	                        "env.KUBERNETES_REPO=#{the_repo}",
	                        "env.VERBOSE=true"
  end
  @teststatus.success?
end
