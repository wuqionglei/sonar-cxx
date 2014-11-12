Feature: Providing test execution numbers

  As a SonarQube user
  I want to import the test execution reports into SonarQube
  In order to have the text execution metrics in SonarQube and use such SonarQube features as:
  - continuous monitoring of those metrics
  - Quality Gates on top of those metrics
  - Overview over the test execution status
  - ...

  |
  | Specification:
  | * The plugin is able to import test which conform to the schema described in xunit-schema.rnc
  | * Additionaly, the plugin is able to import every XML format 'X' when given an XSLT-sheet,
  |   which performs the X->JUnitReport conversion
  | * To locate the test source file, there are several strategies:
  |   1. The content of the property 'classname' is used to match to classnames in
  |      the AST. This requires the test sources to be actually parsable.
  |   2. If the testcase-tags have a property 'filename', its content is assumed to
  |      contain a relative path to the according test source file.
  |   ?? same for classname-content, actually??


  # This feature will contain (hopefully all of) following tests:
  # == Positive tests ==

  # Category 1:
  # Analysing complete projects with locating the test sources:
  # i.e a bunch of real-world & building projects holding tests,
  # the reports are generated by the test-runners and unchaged.
  # It is noted, how the reports were generated
  # (version, the parameters, operating system). Examples:
  # - googletest with unchanged reports
  # - googletest with filename-tag-augmented reports
  # - cppunit??
  # - boost??

  # Category 2: (later)
  # Simple mode tests. These one dont try to locate the test resources
  # and save the measures in context of them.  The testcases are
  # toolchain agnostic, the only thing that matters is the validity of
  # the passed XML.

  # Category 3: (maybe)
  # Micro-tests: *minimal* scenarios, which are testing only one feature at a time, e.g:
  # - locating a resource via the AST,
  # - locating a resource via the filename-tag
  # - transforming boost report
  # - transforming cppunit report
  # - ...

  # == Negative tests ==
  # Those also should be toolchain agnostic and test certain failure conditions. For example:
  # - Tests cannot be found
  # - Tests are invalid or empty
  # - the given XSLT is invalid
  # - the transformation cannot be done because of a faulty (cppunit?)-report


  @wip
  Scenario: Importing an unchanged test report generated by googletest
      GIVEN the project "googletest_project"

      WHEN I run "sonar-runner -X -Dsonar.cxx.xunit.reportPath=googletest_report.xml"

      THEN the analysis finishes successfully
          AND the analysis log contains no error/warning messages except those matching:
              """
              .*WARN.*cannot find the sources for '#include <iostream>'
              .*WARN.*cannot find the sources for '#include <gtest/gtest.h>'
              """
          AND the following metrics have following values:
               | metric               | value |
               | tests                | 4     |
               | test_failures        | 2     |
               | test_errors          | 0     |
               | skipped_tests        | 1     |
               | test_success_density | 33.3  |
               | test_execution_time  | 0.0   |


  Scenario: Importing a googletest-generated-report augmented with the filename-tag
      #
      # The filename tag is a custom extension of the JUnitReport
      # format (introduced by sonar-cxx) which is used to locate the
      # test resources.
      #
      GIVEN the python project "googletest_project"

      WHEN I run "sonar-runner -Dsonar.cxx.xunit.reportPath=..."

      THEN the analysis finishes successfully
          AND the analysis log contains no error or warning messages
          AND the following metrics have following values:
               | metric               | value |
               | tests                | 3.0   |
               | test_failures        | 1.0   |
               | test_errors          | 1.0   |
               | skipped_tests        | 1.0   |
               | test_success_density | 33.3  |
               | test_execution_time  | 1.0   |


  # Scenario: Importing a test report augmented with the filename-tag
  #     #
  #     # can be formulated as an outline with various 'flavors' of JUnitReport
  #     # and resulting metrics being the parameters
  #     #
  #     GIVEN the python project "googletest_project"

  #     WHEN I run "sonar-runner -Dsonar.cxx.xunit.reportPath=..."

  #     THEN the analysis finishes successfully
  #         AND the analysis log contains no error or warning messages
  #         AND the following metrics have following values:
  #              | metric               | value |
  #              | tests                | 3.0   |
  #              | test_failures        | 1.0   |
  #              | test_errors          | 1.0   |
  #              | skipped_tests        | 1.0   |
  #              | test_success_density | 33.3  |
  #              | test_execution_time  | 1.0   |


  Scenario Outline: Importing a test reports with conversion via XSLT
      GIVEN the python project "xunit_project"

      WHEN I run <command>
      THEN the analysis finishes successfully
          AND the analysis log contains no error or warning messages
          AND the test metrics have following values: <values>

      Examples:
      | command                                                       | values              |
      | "sonar-runner -Dsonar.cxx.xunit.reportPath=boostreport.xml"   | 3.0, 1.0, 1.0, 1,0  |
      | "sonar-runner -Dsonar.cxx.xunit.reportPath=cppunitreport.xml" | 3.0, 1.0, 1.0, 1,0  |


  Scenario: Test reports cannot be found
      GIVEN the python project "googletest_project"

      WHEN I run "sonar-runner -Dsonar.cxx.xunit.reportPath=habadubada"
      THEN the analysis finishes successfully
          AND the analysis log contains no error or warning messages
          AND the following metrics have following values:
              | metric               | value |
              | tests                | None  |
              | test_failures        | None  |
              | test_errors          | None  |
              | skipped_tests        | None  |
              | test_success_density | None  |
              | test_execution_time  | None  |


  Scenario Outline: Test report is invalid
      GIVEN the python project "googletest_project"

      WHEN I run "sonar-runner -Dsonar.cxx.xunit.reportPath=<reportpath>"

      THEN the analysis breaks
          AND the analysis log contains a line matching:
              """
              ERROR.*Cannot feed the data into sonar, details: .*
              """

      Examples:
          | reportpath         |
          | invalid_report.xml |
          | empty_report.xml   |
