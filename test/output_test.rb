require File.expand_path('../helper', __FILE__)

class Librato::Services::OutputTestCase < Test::Unit::TestCase
  ENV['METRICS_APP_URL'] = 'metrics.librato.com'
  def test_clear
    payload = {
      alert: {id: 123, name: "Some alert name", version: 2},
      settings: {},
      service_type: "campfire",
      event_type: "alert",
      trigger_time: 12321123,
      clear: "normal"
    }
    output = Librato::Services::Output.new(payload)
    expected = <<EOF
# Alert Some alert name has cleared at 1970-05-23 14:32:03 UTC

Link: https://metrics.librato.com/alerts/123
EOF
    assert_equal(expected, output.markdown)
  end

  def test_clear_auto
    payload = {
      alert: {id: 123, name: "Some alert name", version: 2},
      settings: {},
      service_type: "campfire",
      event_type: "alert",
      trigger_time: 12321123,
      clear: "auto"
    }
    output = Librato::Services::Output.new(payload)
    expected = <<EOF
# Alert Some alert name was automatically cleared at 1970-05-23 14:32:03 UTC

Link: https://metrics.librato.com/alerts/123
EOF
    assert_equal(expected, output.markdown)
  end

  def test_clear_manual
    payload = {
      alert: {id: 123, name: "Some alert name", version: 2},
      settings: {},
      service_type: "campfire",
      event_type: "alert",
      trigger_time: 12321123,
      clear: "manual"
    }
    output = Librato::Services::Output.new(payload)
    expected = <<EOF
# Alert Some alert name was manually cleared at 1970-05-23 14:32:03 UTC

Link: https://metrics.librato.com/alerts/123
EOF
    assert_equal(expected, output.markdown)
  end

  def test_clear_unknown
    payload = {
      alert: {id: 123, name: "Some alert name", version: 2},
      settings: {},
      service_type: "campfire",
      event_type: "alert",
      trigger_time: 12321123,
      clear: "unsupported"
    }
    output = Librato::Services::Output.new(payload)
    # fall back to the 'normal' case
    expected = <<EOF
# Alert Some alert name has cleared at 1970-05-23 14:32:03 UTC

Link: https://metrics.librato.com/alerts/123
EOF
    assert_equal(expected, output.markdown)
  end

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

Link: https://metrics.librato.com/alerts/123

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
        {type: "absent", threshold: nil, duration:600, id:3}
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

Link: https://metrics.librato.com/alerts/123

Source `foo.bar`:
* metric `metric.name` was above threshold 10 with value 100 recorded at Fri, Jan 10 2014 at 21:58:03 UTC

Source `baz.lol`:
* metric `something.else` was above threshold 10 with value 250 recorded at Fri, Jan 10 2014 at 21:58:03 UTC
* metric `another.metric` was below threshold 100 with value 10 recorded at Fri, Jan 10 2014 at 21:58:03 UTC
* metric `i.am.absent` was absent for 600 seconds recorded at Fri, Jan 10 2014 at 21:58:03 UTC
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

Link: https://metrics.librato.com/alerts/123

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

Link: https://metrics.librato.com/alerts/123

Source `foo.bar`:
* metric `metric.name` was above threshold 10 with value 100 recorded at Fri, Jan 10 2014 at 21:58:03 UTC

Runbook: http://example.com/
EOF
    assert_equal(expected, output.markdown)
  end

  # Escape underscores in alert name when rendering html
  def test_escape_underscores_in_alert_name
    payload = {
        alert: {id: 123, name: "Some_alert_name", version: 2, runbook_url: "http://example.com/"},
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
# Alert Some\\_alert\\_name has triggered!

Link: https://metrics.librato.com/alerts/123

Source `foo.bar`:
* metric `metric.name` was above threshold 10 with value 100 recorded at Fri, Jan 10 2014 at 21:58:03 UTC

Runbook: http://example.com/
EOF
    assert_equal(expected, output.generate_markdown(is_html=true))
  end
end
