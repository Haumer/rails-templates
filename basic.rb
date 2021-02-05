run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# GEMFILE
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY
    gem 'devise'
    gem 'autoprefixer-rails'
    gem 'font-awesome-sass'
    gem 'simple_form'
    gem 'pundit'
    gem 'view_component', require: 'view_component/engine'
  RUBY
end

inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'dotenv-rails'
  RUBY
end

gsub_file('Gemfile', /# gem 'redis'/, "gem 'redis'")

inject_into_file 'app/assests/stylesheets/componentsindex.scss', <<~CSS
  @import 'flashes';
CSS

inject_into_file 'app/assests/stylesheets/components_flashes.scss', <<~CSS
  .alert {
    position: fixed;
    bottom: 16px;
    right: 16px;
    z-index: 1000;
  }

  .notice {
    position: fixed;
    bottom: 16px;
    right: 16px;
    z-index: 1000;
  }

  .success {
    position: fixed;
    bottom: 16px;
    right: 16px;
    z-index: 1000;
  }
CSS

# Dev environment
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Layout
if Rails.version < "6"
  scripts = <<~HTML
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>
    <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
  HTML
  gsub_file('app/views/layouts/application.html.erb', "<%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>", scripts)
end
gsub_file('app/views/layouts/application.html.erb', "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>", "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>")
style = <<~HTML
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
HTML
gsub_file('app/views/layouts/application.html.erb', "<%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>", style)

# Flashes
file 'app/views/shared/_flashes.html.erb', <<~HTML
  <% if notice %>
    <div class="alert alert-info alert-dismissible fade show m-1" role="alert">
      <%= notice %>
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  <% end %>
  <% if alert %>
    <div class="alert alert-warning alert-dismissible fade show m-1" role="alert">
      <%= alert %>
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  <% end %>
  <% if success %>
    <div class="alert alert-success alert-dismissible fade show m-1" role="alert">
      <%= alert %>
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  <% end %>
HTML

run 'curl -L https://github.com/lewagon/awesome-navbars/raw/master/templates/_navbar_wagon.html.erb > app/views/shared/_navbar.html.erb'

inject_into_file 'app/views/layouts/application.html.erb', after: '<body>' do
  <<-HTML
    <%= render 'shared/navbar' %>
    <%= render 'shared/flashes' %>
  HTML
end

# README
markdown_file_content = <<-MARKDOWN
Template by [Haumer](https://www.github.com/haumer).
MARKDOWN
file 'README.md', markdown_file_content, force: true

# Generators
generators = <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :test_unit, fixture: false
  end
RUBY

environment generators

# AFTER BUNDLE
after_bundle do
  # Assets
  run 'rm -rf vendor'
  Dir.mkdir 'app/assests/stylesheets/components'
  run 'touch app/assests/stylesheets/components/_flashes.scss'
  run 'touch app/assests/stylesheets/components/index.scss'

  # Navbar
  Dir.mkdir 'mkdir app/views/shared'
  run 'touch app/views/shared/_navbar.html.erb'
  inject_into_file 'app/views/shared/_navbar.html.erb', <<~HTML
    <div class="navbar navbar-expand-sm navbar-light navbar-lewagon">
      <%= link_to "#", class: "navbar-brand" do %>
        <%= image_tag "https://avatars.githubusercontent.com/u/28539586?v=4" %>
        <% end %>

      <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
        <span class="navbar-toggler-icon"></span>
      </button>


      <div class="collapse navbar-collapse" id="navbarSupportedContent">
        <ul class="navbar-nav mr-auto">
          <% if user_signed_in? %>
            <li class="nav-item active">
              <%= link_to "Home", "#", class: "nav-link" %>
            </li>
            <li class="nav-item">
              <%= link_to "Messages", "#", class: "nav-link" %>
            </li>
            <li class="nav-item dropdown">
              <%= image_tag "https://avatars.githubusercontent.com/u/28539586?v=4", class: "avatar dropdown-toggle", id: "navbarDropdown", data: { toggle: "dropdown" }, 'aria-haspopup': true, 'aria-expanded': false %>
              <div class="dropdown-menu dropdown-menu-right" aria-labelledby="navbarDropdown">
                <%= link_to "Action", "#", class: "dropdown-item" %>
                <%= link_to "Another action", "#", class: "dropdown-item" %>
                <%= link_to "Log out", destroy_user_session_path, method: :delete, class: "dropdown-item" %>
              </div>
            </li>
          <% else %>
            <li class="nav-item">
              <%= link_to "Login", new_user_session_path, class: "nav-link" %>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
  HTML

  # Generators: db + simple form + pages controller
  rails_command 'db:drop db:create db:migrate'
  generate('simple_form:install', '--bootstrap')
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')

  # Routes
  route "root to: 'pages#home'"

  # Git ignore
  append_file '.gitignore', <<~TXT
    .env*
    .DS_Store
  TXT

  # Devise install + user
  generate('devise:install')
  generate('devise', 'User')

  # App controller
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<~RUBY
    class ApplicationController < ActionController::Base
    #{  "protect_from_forgery with: :exception\n" if Rails.version < "5.2"  }  before_action :authenticate_user!
    end
  RUBY

  # migrate + devise views
  rails_command('db:migrate')
  generate('devise:views')

  # Pages Controller
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<~RUBY
    class PagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :home ]
      def home
      end
    end
  RUBY

  # Environments
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Webpacker / Yarn
  run 'yarn add popper.js jquery bootstrap stimulus'
  append_file 'app/javascript/packs/application.js', <<~JS
    import "bootstrap";
    document.addEventListener('turbolinks:load', () => {

    });
  JS

  # Stimulus
  Dir.mkdir 'mkdir app/javascript/controllers'
  run 'touch app/javascript/controllers/index.js'

  append_file 'app/javascript/packs/application.js', <<~JS
    import 'controllers';
  JS

  inject_into_file 'app/javascript/controllers/index.js', <<~JS
    import { Application } from "stimulus";
    import { definitionsFromContext } from "stimulus/webpack-helpers";

    const application = Application.start();
    const context = require.context(".", true, /\.js$/);
    application.load(definitionsFromContext(context));
  JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do
    <<~JS
      const webpack = require('webpack');
      environment.loaders.delete('nodeModules');
      environment.plugins.prepend('Provide',
        new webpack.ProvidePlugin({
          $: 'jquery',
          jQuery: 'jquery',
          Popper: ['popper.js', 'default']
        })
      );
    JS
  end

  # Dotenv
  run 'touch .env'

  # Rubocop
  run 'curl -L https://raw.githubusercontent.com/haumer/rails-templates/master/.rubocop.yml > .rubocop.yml'

  # Git
  git add: '.'
  git commit: "-m 'Initial commit with a template from https://github.com/haumer/rails-templates'"

  # Fix puma config
  gsub_file('config/puma.rb', 'pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }', '# pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }')
end
