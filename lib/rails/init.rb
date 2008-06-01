require 'johnson'

class EJSHandler < ActionView::TemplateHandler
  class EJSProxy # :nodoc:
    def initialize(controller)
      @controller = controller
    end

    def key?(pooperty)
      @controller.instance_variables.include?("@#{pooperty}")
    end

    def [](pooperty)
      @controller.instance_variable_get("@#{pooperty}")
    end

    def []=(pooperty, value)
      @controller.instance_variable_set("@#{pooperty}", value)
    end
  end

  def initialize(view)
    @view = view
  end

  def render(template)
    ctx = Johnson::Runtime.new
    ctx.evaluate('Johnson.require("johnson/template");')
    ctx['template'] = template.source
    ctx['controller'] = @view.controller
    ctx['at'] = EJSProxy.new(@view.controller)

    ctx.evaluate('Johnson.templatize(template).call(at)')
  end
end

ActionView::Template.register_template_handler("ejs", EJSHandler)
