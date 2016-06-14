# Keel

This gem provides a few easy to run rake tasks to deploy your [Rails](http://rubyonrails.org/) application to a [Kubernetes](http://kubernetes.io/) cluster.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'keel'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install keel
```

## Usage

First, run:

```
bin/rails g keel:config
```

to generate the config file and update the attributes with the appropriate values.

This gem mostly provides a set of rake tasks that you can see if you execute `bin/rake -T keel`:

```
rake keel:deploy[environment,deploy_sha]                            # Deploy the specified SHA to a given environment
rake keel:generate:controller[environment,database_url,secret_key]  # Generates a k8s replication controller
rake keel:generate:service[environment]                             # Generates a k8s service
rake keel:logs[environment]                                         # Pulls logs for a given environment
rake keel:setup                                                     # Configures the local machine for communication with gcloud and k8s
```

The first thing you'd want to do after you've setup the configs is to run `bin/rake keel:setup` to make sure your local environment is setup with the right tools to communicate with GCloud and Kubernetes. Just follow the instructions in the command prompt.

Once you have that setup, you can run `bin/rake keel:deploy` to deploy your code to one of your environments on the Kubernetes cluster. You can provide all the necessary information by following the instructions in the command prompt.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/o19s/keel. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
