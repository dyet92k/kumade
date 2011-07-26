require 'spec_helper'

class Kumade
  describe Deployer, "#load_tasks" do
    it "loads the deploy tasks" do
      Rake.application.tasks.should be_empty
      subject.load_tasks
      task_names = Rake.application.tasks.map{|task| task.name }
      %w(deploy deploy:production deploy:staging).each do |expected_name|
        task_names.should include expected_name
      end
    end
  end

  describe Deployer, "#git_push" do
    let(:remote){ 'origin' }

    before { subject.stub(:announce) }

    it "calls `git push`" do
      subject.should_receive(:run).
        with("git push #{remote} master").
        and_return(true)
      subject.git_push(remote)
    end

    context "when `git push` fails" do
      before do
        subject.stub(:run).and_return(false)
      end

      it "raises an error" do
        lambda do
          subject.git_push(remote)
        end.should raise_error("Failed to push master -> #{remote}")
      end
    end

    context "when `git push` succeeds" do
      before do
        subject.stub(:run).and_return(true)
      end

      it "does not raise an error" do
        subject.stub(:announce).and_return(false)
        lambda do
          subject.git_push(remote)
        end.should_not raise_error
      end

      it "prints the correct message" do
        subject.should_receive(:announce).
          with("Pushed master -> #{remote}")

        subject.git_push(remote)
      end
    end
  end

  describe Deployer, "#git_force_push" do
    let(:remote){ 'origin' }
    before { subject.stub(:announce) }

    it "calls `git push -f`" do
      subject.should_receive(:run).
        with("git push -f #{remote} master").
        and_return(true)
      subject.git_force_push(remote)
    end

    context "when `git push -f` fails" do
      before do
        subject.stub(:run).and_return(false)
      end

      it "raises an error" do
        lambda do
          subject.git_force_push(remote)
        end.should raise_error("Failed to force push master -> #{remote}")
      end
    end

    context "when `git push -f` succeeds" do
      before do
        subject.stub(:run).and_return(true)
      end

      it "does not raise an error" do
        lambda do
          subject.git_force_push(remote)
        end.should_not raise_error
      end

      it "prints the correct message" do
        subject.should_receive(:announce).
          with("Force pushed master -> #{remote}")

        subject.git_force_push(remote)
      end
    end
  end

  describe Deployer, "#ensure_clean_git" do
    context "when git is dirty" do
      before { subject.stub(:git_dirty?).and_return(true) }

      it "raises an error" do
        lambda do
          subject.ensure_clean_git
        end.should raise_error("Cannot deploy: repo is not clean.")
      end
    end

    context "when git is clean" do
      before { subject.stub(:git_dirty?).and_return(false) }

      it "does not raise an error" do
        lambda do
          subject.ensure_clean_git
        end.should_not raise_error
      end
    end
  end

  describe Deployer, "#ensure_rake_passes" do
    context "with a default task" do
      before do
        subject.stub(:default_task_exists?).and_return(true)
      end

      it "does not raise an error if the default task succeeds" do
        subject.stub(:rake_succeeded?).and_return(true)
        lambda do
          subject.ensure_rake_passes
        end.should_not raise_error
      end

      it "raises an error if the default task failse" do
        subject.stub(:rake_succeeded?).and_return(false)
        lambda do
          subject.ensure_rake_passes
        end.should raise_error("Cannot deploy: tests did not pass")
      end
    end
  end

  describe Deployer, "#default_task_exists?" do
    before { Rake::Task.clear }

    it "returns true if a default task does exist" do
      Rake::Task.define_task(:default){}

      subject.default_task_exists?.should be_true
    end

    it "returns false if a default task does not exist" do
      subject.default_task_exists?.should be_false
    end
  end

  describe Deployer, "#rake_succeeded?" do
    before { Rake::Task.clear }

    it "returns true if the default task passed" do
      Rake::Task.define_task(:default){}

      subject.rake_succeeded?.should be_true
    end

    it "returns false if the default task failed" do
      Rake::Task.define_task(:default){ fail "blerg" }
      subject.rake_succeeded?.should be_false
    end
  end
end