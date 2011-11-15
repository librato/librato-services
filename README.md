Librato Services
================

Service hooks for [Librato Metrics][https://metrics.librato.com].

Service Lifecycle
-----------------

1. When a metric measurement is posted to the API that exceeds a
   configured alert threshold, the API records the exception.
1. A background job checks every minute for any alerts that have been
   triggered.
2. If xany alerts have been triggered, the background job generates a
   POST to
   `https://<services-server>/services/<service_name>/alert.json` with
   the post data:
   - `params[:settings]`: the options the user specified in the Service configuration
   - `params[:payload]`: the event data for the triggered alert
3. A [sinatra][] app [lib/librato_services/app.rb][] decodes the request
   and dispatches it to a registered service if it exists


Writing a Service
-----------------

All services are found in the [services/][] directory. They must have a method
named `receive_alert` that is called when an alert is matched.

The settings are available as a `Hash` in the instance method `settings` and
the event payload is available as a `Hash` in the instance method `payload`.

Tests should accompany all services and are located in the [services/][]
directory.

Payload
-------

```
'payload' : {
        'alert' : {
                'name' : 'Alert name or nil',
                'id' : 12345,
        },
        'metric' : {
                 'name' : 'Name of the metric that tripped alert',
                 'type' : 'gauge' or 'counter',
        },
        'measurement' : {
                 'value' : 4.5 (value that caused exception),
                 'source' : 'source name',
        }
}
```


Sample Service
--------------

Here's a simple service that posts the measurement value that
triggered the alert.

```ruby
class Service::Sample < Service
  def receive_alert
    value = payload[:measurement][:value]

    http_post 'https://sample-service.com/post.json' do |req|
      req.body = {
        settings[:name] => value
      }
    end
  end
end
```

Contributing
------------

Once you've made your great commits:

1. [Fork][fk] `librato_services`
2. Create a topic branch — `git checkout -b my_branch`
3. Commit the changes without changing the Rakefile or other files unrelated to your enhancement.
4. Push to your branch — `git push origin my_branch`
5. Create a Pull Request or an [Issue][is] with a link to your branch
6. That's it!


Credits
-------

This project is heavily influenced in spirit and code by
[papertrail-services][] and [github-services][].
We love what GitHub has done for all of us and what they have demonstrated
can be accomplished with community involvement.

We thank them for everything they've done for all of us.

[lib/librato_services/app.rb]: https://github.com/librato/librato-services/blob/master/lib/librato_services/app.rb
[services/]: https://github.com/librato/librato-services/tree/master/services
[test/]: https://github.com/librato/librato-services/tree/master/test
[github-services]: https://github.com/github/github-services/
[papertrail-services]: https://github.com/papertrail/papertrail-services/
[sinatra]: http://www.sinatrarb.com/
[fk]: http://help.github.com/forking/
[is]: https://github.com/librato/librato_services/issues/
[Librato]: http://librato.com/
