#!/bin/bash

# Writes CI reports to the GitHub Actions job summary ($GITHUB_STEP_SUMMARY).

SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

test_and_coverage_summary() {
    {
        echo "## Test Results"
        if [ -f test-results/junit.xml ]; then
            ruby -rrexml/document -e '
                t = {tests: 0, failures: 0, errors: 0, time: 0.0}
                REXML::Document.new(File.read("test-results/junit.xml")).elements.each("//testsuite") do |s|
                    t[:tests]    += s.attributes["tests"].to_i
                    t[:failures] += s.attributes["failures"].to_i
                    t[:errors]   += s.attributes["errors"].to_i
                    t[:time]     += s.attributes["time"].to_f
                end
                puts "| Tests | Failures | Errors | Time |"
                puts "|------:|---------:|-------:|-----:|"
                puts "| #{t[:tests]} | #{t[:failures]} | #{t[:errors]} | #{"%.2f" % t[:time]}s |"
            '
        else
            echo "_No test results found._"
        fi
        echo ""
        echo "## Code Coverage"
        if [ -f coverage-results/coverage.txt ]; then
            echo '```'
            cat coverage-results/coverage.txt
            echo '```'
        else
            echo "_No coverage report found._"
        fi
    } >> "$SUMMARY_FILE"
}

sdk_size_summary() {
    {
        echo "## SDK Size Report"
        if [ -f sizes.txt ]; then
            echo '```'
            cat sizes.txt
            echo '```'
        else
            echo "_No size report found._"
        fi
    } >> "$SUMMARY_FILE"
}

# Run based on the argument passed to the script
case "$1" in
    test-and-coverage)
        test_and_coverage_summary
        ;;
    sdk-size)
        sdk_size_summary
        ;;
    *)
        echo "Usage: $0 {test-and-coverage|sdk-size}"
        exit 1
        ;;
esac
