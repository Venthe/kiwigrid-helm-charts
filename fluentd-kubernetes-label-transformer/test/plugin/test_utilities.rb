def basic_config
%[
]
end

def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::RegexpSplitterFilter).configure(conf)
end