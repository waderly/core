#!/usr/bin/env luajit

require [[includes.bootstrap]]

settings.output_buffering = false

ophal.bootstrap(function ()
  if not settings.maintenance_mode then
    module_invoke_all [[cron]]
  end
end)