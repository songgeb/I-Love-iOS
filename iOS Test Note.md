# iOS Test笔记

Criteria

- Fast: Tests should run quickly.
- Independent/Isolated: Tests shouldn’t share state with each other.
- Repeatable: You should obtain the same results every time you run a test. External data providers or concurrency issues could cause intermittent failures.
- Self-validating: Tests should be fully automated. The output should be either “pass” or “fail”, rather than relying on a programmer’s interpretation of a log file.
- Timely: Ideally, you should write your tests before writing the production code they test. This is known as test-driven development.

## Terms

sut: System Under Test，待测系统


## UI Test

UI testing lets you test interactions with the user interface. UI testing works by finding an app’s UI objects with queries, synthesizing events and then sending the events to those objects. The API enables you to examine a UI object’s properties and state to compare them against the expected state.

```
// given
let slideButton = app.segmentedControls.buttons["Slide"]
let typeButton = app.segmentedControls.buttons["Type"]
let slideLabel = app.staticTexts["Get as close as you can to: "]
let typeLabel = app.staticTexts["Guess where the slider is: "]
// then
if slideButton.isSelected {
  XCTAssertTrue(slideLabel.exists)
  XCTAssertFalse(typeLabel.exists)

  typeButton.tap()
  XCTAssertTrue(typeLabel.exists)
  XCTAssertFalse(slideLabel.exists)
}
```

## Testing Performance
A performance test takes a block of code that you want to evaluate and runs it ten times, collecting the average execution time and the standard deviation for the runs. The averaging of these individual measurements form a value for the test run that can then be compared against a baseline to evaluate success or failure.

> Baselines are stored per device configuration, so you can have the same test executing on several different devices. Each can maintain a different baseline dependent upon the specific configuration’s processor speed, memory, etc.

```
func testScoreIsComputedPerformance() {
  measure(
    metrics: [
      XCTClockMetric(), 
      XCTCPUMetric(),
      XCTStorageMetric(), 
      XCTMemoryMetric()
    ]
  ) {
    sut.check(guess: 100)
  }
}
```

## QA

1. what is code coverage tool
2. “Fake interactions with library or system objects by using stubs and mocks”，what is stubs？

## 参考
- [What is @testable?](https://medium.com/@ani.sam2015/what-is-testable-c26ee882ada4)
- [iOS Unit Testing and UI Testing Tutorial](https://www.raywenderlich.com/21020457-ios-unit-testing-and-ui-testing-tutorial)