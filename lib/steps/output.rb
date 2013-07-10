# encoding: utf-8
STDOUT.sync
require 'colored'
require 'highline'
require 'steps/spinner'

module Steps
  class Output

    @spinner = Steps::Spinner.new
    @task_depth = 0
    @stacked_result = false
    @highline = HighLine.new

    def self.step(desc, options)
      self.start_to desc
      begin
        smessage = yield
        smessage = "✔" unless smessage.is_a? String
        self.success smessage
      rescue Exception => e
          message = e.message.empty? ? "X" : e.message

          self.error(message)
          if options[:vital]
            if @task_depth > 1
              raise "X"
            else
              exit
            end
          end
      end
    end

    def self.start_to message
      lead_str = ""
      if @spinner.running?
        @spinner.stop
        if @stacked_result
          lead_str = "\r#{`tput el`}"
        else
          lead_str = "\n"
        end
      end

      if @task_depth > 0
        message = lead_str + ("|   " * (@task_depth - 1)) + "├── " + message
      end

      print "#{message}".yellow + "   "
      @spinner.start
      @task_depth += 1
      @stacked_result = false
    end

    def self.result message
      @spinner.stop

      puts message

      if @task_depth > 0
        @task_depth -= 1
        if @task_depth > 0
          print "|   ".yellow * (@task_depth - 1)
          @spinner.start
        end
      end
      @stacked_result = true
    end

    def self.error message
      if @spinner.running?
        @spinner.stop
      end
      self.result message.red
    end

    def self.error_and_exit message
      self.error message
      exit
    end

    def self.success message
      self.result message.green
    end

    def self.info message
      self.result message.blue
    end

    def self.confirm(message, options={})
      message = message + " (y|n) > "
      message = (options[:vital] ? message.red : message.blue) + " "
      message = "├── ".yellow + message if @task_depth > 0
      @spinner.stop
      unless @stacked_result
        print "\n" + ("|   ".yellow * (@task_depth - 1))
      end
      result = @highline.agree(message)
      if @task_depth > 0
        print "|   ".yellow * (@task_depth - 1)
        @spinner.start
      end

      if options[:vital] and not result
        if @task_depth > 0
          raise "Aborting"
        else
          self.error_and_exit "Aborting"
        end
      end

      @stacked_result = true
      return result
    end

    def self.retrieve(message, answer_type, &block)
      message = message + " > "
      message = message.blue + " "
      message = "├── ".yellow + message if @task_depth > 0
      @spinner.stop
      result = @highline.ask(message, answer_type, &block)
      if @task_depth > 0
        print "|   ".yellow * (@task_depth - 1)
        @spinner.start
      end
      return result
    end
  end
end
