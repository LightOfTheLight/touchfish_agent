# Tests

## Unit test script

Run the unit tests with Docker (recommended):

```bash
./tests/unit_test.sh
```

This will build a one-time test image, copy the workspace into a container, and run the tests inside it. The report is written to:

```
./tests/report.txt
```

## Running inside a container manually

If you already have the image built, you can run a container without bind mounts:

```bash
container_id=$(docker create \
  -e RUN_IN_CONTAINER=1 \
  -e TEST_REPORT=/work/tests/report.txt \
  touchfish_agent_test \
  /work/tests/unit_test.sh)
docker cp "$(pwd)" "${container_id}:/work"
docker start -a "${container_id}"
docker cp "${container_id}:/work/tests/report.txt" ./tests/report.txt
docker rm "${container_id}"
```

## Notes

- The unit tests mock `gh` and `codex` via `tests/mocks`.
- The unit tests mock `git` to avoid network push.
- Test data lives in `tests/data`.
