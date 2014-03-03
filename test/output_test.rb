require File.expand_path('../helper', __FILE__)

class Librato::Services::OutputTestCase < Test::Unit::TestCase
  def test_simple_alert
    payload = {
      alert: {id: 123, name: "Some alert name", version: 2},
      settings: {},
      service_type: "campfire",
      event_type: "alert",
      trigger_time: 12321123,
      conditions: [{type: "above", threshold: 10, id: 1}],
      violations: {
        "foo.bar" => [{
          metric: "metric.name", value: 100, recorded_at: 1389391083,
          condition_violated: 1
        }]
      }
    }
    output = Librato::Services::Output.new(payload)
    expected = <<EOF
# Alert Some alert name has triggered!

Source `foo.bar`:
* metric `metric.name` was above threshold 10 with value 100 recorded at Fri, Jan 10 2014 at 21:58:03 UTC
EOF
    assert_equal(expected, output.markdown)
  end

  def test_complex_alert
    payload = {
      alert: {id: 123, name: "Some alert name", version: 2},
      settings: {},
      service_type: "campfire",
      event_type: "alert",
      trigger_time: 12321123,
      conditions: [
        {type: "above", threshold: 10, id: 1},
        {type: "below", threshold: 100, id: 2},
        {type: "absent", threshold: nil, id:3}
      ],
      violations: {
        "foo.bar" => [{
          metric: "metric.name", value: 100, recorded_at: 1389391083,
          condition_violated: 1
        }],
        "baz.lol" => [
          {metric: "something.else", value: 250, recorded_at: 1389391083,
          condition_violated: 1},
          {metric: "another.metric", value: 10, recorded_at: 1389391083,
          condition_violated: 2},
          {metric: "i.am.absent", value: 321, recorded_at: 1389391083,
          condition_violated: 3}
        ]
      }
    }
    output = Librato::Services::Output.new(payload)
    expected = <<EOF
# Alert Some alert name has triggered!

Source `foo.bar`:
* metric `metric.name` was above threshold 10 with value 100 recorded at Fri, Jan 10 2014 at 21:58:03 UTC

Source `baz.lol`:
* metric `something.else` was above threshold 10 with value 250 recorded at Fri, Jan 10 2014 at 21:58:03 UTC
* metric `another.metric` was below threshold 100 with value 10 recorded at Fri, Jan 10 2014 at 21:58:03 UTC
* metric `i.am.absent` was absent recorded at Fri, Jan 10 2014 at 21:58:03 UTC
EOF
    assert_equal(expected, output.markdown)
  end

  def test_bad_payload
    assert_raise RuntimeError do
      output = Librato::Services::Output.new({})
    end

    assert_raise NoMethodError do
      output = Librato::Services::Output.new({:conditions => "", :violations => ""})
    end
  end

  def test_lax_spacing_enabled

    markdown = <<EOF
# Alert Some alert name has triggered!

Source `foo.bar`:
* metric `metric.name` was above threshold 10 with value 100 recorded at Fri, Jan 10 2014 at 21:58:03 UTC
EOF
    expected = <<EOF
<h1>Alert Some alert name has triggered!</h1>

<p>Source <code>foo.bar</code>:</p>

<ul>
<li>metric <code>metric.name</code> was above threshold 10 with value 100 recorded at Fri, Jan 10 2014 at 21:58:03 UTC</li>
</ul>
EOF

    assert_equal(expected, Librato::Services::Output.renderer.render(markdown))
  end

  def test_windowed_alert
    payload = {
        alert: {id: 123, name: "Some alert name", version: 2},
        settings: {},
        service_type: "campfire",
        event_type: "alert",
        trigger_time: 12321123,
        conditions: [{type: "above", threshold: 10, id: 1}],
        violations: {
            "foo.bar" => [{
                              metric: "metric.name", value: 100, recorded_at: 1389391083,
                              condition_violated: 1, count: 10, begin: 12321123, end: 12321183
                          }]
        }
    }
    output = Librato::Services::Output.new(payload)
    expected = <<EOF
# Alert Some alert name has triggered!

Source `foo.bar`:
* metric `metric.name` was above threshold 10 over 60 seconds with value 100 recorded at Fri, Jan 10 2014 at 21:58:03 UTC
EOF
    assert_equal(expected, output.markdown)
  end

  def test_runbook_url
    payload = {
        alert: {id: 123, name: "Some alert name", version: 2, runbook_url: "http://example.com/"},
        settings: {},
        service_type: "campfire",
        event_type: "alert",
        trigger_time: 12321123,
        conditions: [{type: "above", threshold: 10, id: 1}],
        violations: {
            "foo.bar" => [{
                              metric: "metric.name", value: 100, recorded_at: 1389391083,
                              condition_violated: 1
                          }]
        }
    }
    output = Librato::Services::Output.new(payload)
    expected = <<EOF
# Alert Some alert name has triggered!

Source `foo.bar`:
* metric `metric.name` was above threshold 10 with value 100 recorded at Fri, Jan 10 2014 at 21:58:03 UTC

Runbook: http://example.com/
EOF
    assert_equal(expected, output.markdown)
  end
end
