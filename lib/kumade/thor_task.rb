require 'thor'

module Kumade
  class ThorTask < Thor
    default_task :deploy

    desc "deploy [ENV]", "Deploy to ENV (default: staging)"
    method_option :pretend, :aliases => "-p", :desc => "Pretend Mode - print out what kumade would do"
    def deploy(environment = 'staging')
      say("==> In Pretend Mode", :red) if options[:pretend]
      say "==> Deploying to: #{environment}"

      unless options[:pretend]
        Kumade.deployer.deploy_to(environment)
      end

      say "==> Deployed to: #{environment}", :green
    end
  end
end