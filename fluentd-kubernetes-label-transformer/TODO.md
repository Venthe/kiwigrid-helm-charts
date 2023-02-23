Create a plugin that will work with conjuction with Kubernetes Metadata plugin
This will allow for each pod to optionally specify a logging pattern

1. Take a label from parsed log file, i.e.
   ```yaml
   kubernetes:
     label:
       venthe_eu/log_regexp: "^\[(?<time>.*?)\]\s+\[(?<thread>.*?)\]\s+(?<logLevel>\w+?)\s+(?<package>.*)\s+:\s+(?<message>.*)$"
   ```
2. Transform the key [`log`?] to a `message` plus ancillary fields; merge it back together
   ```ruby
   dict={
     "log"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache",
     "regexp"=> "^\\[(?<time>.*?)\\]\\s+\\[(?<thread>.*?)\\]\\s+(?<logLevel>\\w+?)\\s+(?<package>.*)\\s+:\\s+(?<message>.*)$"
   }

   Regexp.new(dict.key?("regexp") ? dict["regexp"] + "|^(?<message>.*)$" : "^(?<message>.*)$").match(dict["log"]).named_captures.merge(dict)
   ```


