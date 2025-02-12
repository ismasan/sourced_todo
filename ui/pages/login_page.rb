module Pages
  class LoginPage < Phlex::HTML
    def initialize(params: {}, errors: {})
      @params = params
      @errors = errors
    end

    def view_template
      Layouts::Login(title: 'Login') do
        div id: 'container', class: 'container login-container' do
          div(id: 'login-box', class: [('errors' if @errors.any?)]) do
            h1 { 'Login' }
            form(action: '/login', method: 'post', class: 'nice-form') do
              p { 'Please create a user name to begin' }
              if @errors.any?
                h4 { 'Errors' }
                ul class: 'error-list' do
                  @errors.each do |k, v|
                    li { "#{k}: #{v}" }
                  end
                end
              end
              div class: 'row' do
                input(
                  type: 'text',
                  name: 'username',
                  placeholder: 'Username',
                  autocomplete: 'off',
                  class: ['nice-input', ('error' if @errors[:username])],
                  required: false
                )
                button(type: 'submit', class: 'nice-button') { 'Login' }
              end
            end
          end
        end
      end
    end
  end
end
