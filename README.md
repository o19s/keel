# Keel

This gem provides a few easy to run rake tasks to deploy your [Rails](http://rubyonrails.org/) application to a [Kubernetes](http://kubernetes.io/) cluster.

[![Gem Version](https://badge.fury.io/rb/keel.svg)](https://badge.fury.io/rb/keel)

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

### Rake Tasks

This gem mostly provides a set of rake tasks that you can see if you execute `bin/rake -T keel`:

```
rake keel:deploy[environment,deploy_sha]                            # Deploy the specified SHA to a given environment
rake keel:logs[environment]                                         # Pulls logs for a given environment
rake keel:setup                                                     # Configures the local machine for communication with gcloud and k8s
```

The first thing you'd want to do after you've setup the configs is to run `bin/rake keel:setup` to make sure your local environment is setup with the right tools to communicate with GCloud and Kubernetes. Just follow the instructions in the command prompt.

Once you have that setup, you can run `bin/rake keel:deploy` to deploy your code to one of your environments on the Kubernetes cluster. You can provide all the necessary information by following the instructions in the command prompt.

### Generators

Other than the config generator that was mentioned above, this gem provides a couple of handy generators to help you work with Kubernetes:

```
keel:controller
keel:service
```

These generators use standard templates to generate a `yml` file that you can use to configure your Kubernetes setup.

You can find the generated files under the `ops/` directory of your application.

## LOLz

Naming is hard, so why not have fun with it?

```
Daniel
Before you commit to that name it, I would like to point out that it is ripe for pun disruption.
Daniel
"You're really keeling it @Youssef"
Matt
crap, our deployment just keeled over
Daniel
"That's a good boy. Down. Sit. Keel."
Doug
We've finally found kubernetes keeler app
Matt
whoa there doug, lets keep this keel
Doug
I know how you keel
Matt
I wonder if we can get an endorsement from my favorite comedy duo?
Matt
Pey and Keele
Daniel
Pen and Keeler
Matt
we should probably keel this before it gets out of hand
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/o19s/keel. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Contributors

* [Chris Bradford](https://github.com/bradfordcp) did the original work
* [Youssef Chaker](https://github.com/ychaker) extracted out the gem

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
