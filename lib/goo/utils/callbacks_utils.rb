module CallbackRunner

  def run_callbacks(inst, callbacks)
    callbacks.each do |proc|
      if instance_proc?(inst, proc)
        call_proc(inst.method(proc))
      elsif proc.is_a?(Proc)
        call_proc(proc)
      end
    end
  end

  def instance_proc?(inst, opt)
    opt && (opt.is_a?(Symbol) || opt.is_a?(String)) && inst.respond_to?(opt)
  end

  def call_proc(proc)
    proc.call
  end


end