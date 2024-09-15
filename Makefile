# Define the default goal
.DEFAULT_GOAL := all

# List of Ruby scripts to execute
RUBY_SCRIPTS = \
	src/tide_stations.rb \
	src/weather_buoys_all.rb \
	src/weather_buoys_active.rb

# Define the 'all' target that will be executed when you run 'make'
all: $(RUBY_SCRIPTS)

# Rule to execute each Ruby script
$(RUBY_SCRIPTS):
	@echo "Executing $@..."
	@ruby $@ || (echo "Error executing $@"; exit 1)
	@echo "------------------------"

# Phony target to ensure the scripts always run
.PHONY: all $(RUBY_SCRIPTS)
