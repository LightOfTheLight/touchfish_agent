# Tests

## Unit test script

Run the unit tests with Docker (recommended):

```bash
./tests/unit_test.sh
```

This will build a one-time test image and run the tests inside a container. The report is written to:

```
./tests/report.txt
```

## Running inside a container manually

If you already have the image built, you can run:

```bash
docker run --rm \
  -e RUN_IN_CONTAINER=1 \
  -e TEST_REPORT=/work/tests/report.txt \
  -v "$(pwd)":/work \
  -w /work \
  touchfish_agent_test \
  /work/tests/unit_test.sh
```

## Notes

- The unit tests mock `gh` and `codex` via `tests/mocks`.
- Test data lives in `tests/data`.
