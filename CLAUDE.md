# Wallaroo Project Exploration Notes

These notes document the exploration of the wallaroo monorepo in preparation for extracting the Pony parts into a new project.

## Project Overview

Wallaroo (aka "Wally") is a distributed stream-processing framework. It's a monorepo with 299 Pony files, 105 Python files, 81 Elixir files, and 3 C files. The primary API is Pony. Python and Go APIs existed but are being dropped.

## What Moves to the New Project

### Pony Core

- **`lib/wallaroo/`** — Core framework library: topology, sources, sinks, recovery, checkpointing, barriers, autoscale, clustering, metrics, routing, state, windowing, etc.
- **`lib/wallaroo_labs/`** — Supporting Pony libraries: bytes, collections, connectors, DAG, FIX protocol, GUID, logging, math, messaging, mort, options, queues, rand, etc.
- **`lib/wallaroo_labs/logging/`** — Contains `logging-lib.c` which compiles to `libwallaroo-logging.a`. All Pony builds depend on this via `$(logging_lib_a)` in `rules.mk`.
- **`examples/pony/`** — 10 Pony example apps: word_count, market_spread, alphabet (with data_gen sub-tool), passthrough, multi_worker_forwarding, celsius-kafka, alerts_stateless, alerts_stateful, alerts_windowed, alerts_local_aggregations.
- **`giles/sender/`** — Pony TCP data sender utility.
- **`utils/`** — 3 Pony utilities: cluster_shrinker, cluster_shutdown, data_receiver.
- **`connectors/pony_connector_sink/`** — Pony connector sink implementation.

### Test Infrastructure

Moving all of `testing/`. This includes both Pony and non-Pony components that support testing the framework.

#### Pony test tools
- `testing/tools/external_sender/` — Pony tool for sending test data
- `testing/tools/fallor/`, `merrick/`, `robson/` — Pony test tools
- `testing/tools/fixed_length_message_blaster/` — Pony test tool
- `testing/tools/fixish_converter/` — Pony FIX data converter
- `testing/tools/fix_generator/` — 3 Pony sub-projects for generating FIX test data

#### Python test infrastructure (keeping — supports Pony testing)
- `testing/tools/integration/` — Python integration test framework (cluster.py, control.py, end_points.py, validations.py, etc.)
- `testing/tools/integration_test` — Python test runner script
- `testing/tools/pytest.ini` — Pytest config
- `testing/tools/connector_sent_data_parser.py`, `sink_output_parser.py` — Python test helpers
- `testing/tools/dos-dumb-object-service/` — Python test service for recovery testing

#### Conformance tests
- `testing/conformance/` — API-agnostic black-box integration test framework (Python). Tests framework behavior by sending TCP data and verifying outputs. Already tests Pony binaries for some apps (system_events uses Pony multi_partition_detector, window_policy uses Pony window_detector). Topology and CLI tests currently only have Python app implementations — need Pony versions written.

#### Correctness test apps (mixed Pony and Python)
Pony apps that move as-is:
- decoder_filter, local_sequence_detector, multi_aggregation, multi_partition_detector (Pony version), multi_pipeline, multi_sink, ping_pong, window_detector (Pony version)

Python test apps that need Pony rewrites:
- dummy_python, parallel_classifier, topology_tester, multi_partition_detector.py, window_detector.py

Python validation scripts (`_validate.py`) alongside Pony apps are test infrastructure and move as-is.

#### Other test content
- `testing/correctness/scripts/` — Shell scripts for effectively-once testing
- `testing/correctness/tests/aloc_sink/` — At-least-once sink tests (Python, uses machida — needs Pony rewrite)
- `testing/performance/apps/market-spread/` — Pony performance test app
- `testing/performance/apps/word_count/` — Pony performance test app
- `testing/performance/apps/python/` — Python performance test apps (need Pony rewrites)
- `testing/data/` — Test data files (market_spread, word_count)

### Documentation

- **`documentation/`** — Hugo-based docs site. Of 42 markdown files, 25 are Pony-relevant. Drop Python tutorial (10 files), Python installation (4 files), Go content (1 file), and Python-specific install guides (2 files). Keep core concepts (6 files, language-agnostic with Pony examples), Pony tutorial (8 files, complete API reference), Pony installation (1 file), operators manual (7 files, need `machida` examples replaced with Pony binary names), appendix (2 files, Giles sender docs), and root landing page. Python and Pony content are in separate directories so it's a clean cut.
- **`book/`** — Two getting-started guides (Docker, Vagrant). Currently Python-focused but moving as templates to rework into Pony-focused getting-started guides for the new project.

### Other

- **`MONOREPO.md`** — May move in some form (project will no longer be a monorepo, but the directory structure description may be useful as a starting point).

### Build System

- **`Makefile`** and **`rules.mk`** — Will need significant rework. See "Build System Details" section below.

## What Does NOT Move

### Non-Pony API Portions (stripping)
- `machida/` — Python 2 API runner (Pony binary embedding Python interpreter via C FFI)
- `machida3/` — Python 3 API runner (same concept)
- `examples/python/` — Python example apps
- `connectors/` (all except `pony_connector_sink/`) — Python connector scripts: kafka_sink, kafka_source, kinesis_sink, kinesis_source, rabbitmq_source, redis_hash_sink, redis_subscriber_source, s3_bucket_sink, udp_sink, udp_source, templates/postgres_*, experimental/alo_kafka_source
- `monitoring_hub/` — Elixir/Phoenix metrics UI (all 81 .exs/.ex files)

### Infrastructure (not relevant to new project)
- `orchestration/` — Ansible, Terraform, Pulumi, Vagrant for cloud provisioning
- `demos/` — No Pony demos exist (python_word_count is Python, resilience-demo is shell/Python)
- `vagrant/` — Local dev VM Vagrantfile
- `docker/`, root `Dockerfile` — Docker build infrastructure tied to full monorepo
- `.circleci/`, `travis/`, `.travis.yml` — CI configs
- `.ci-dockerfiles/` — CI Docker images (install ponyc, stable, Erlang, Python, Go)
- `.release/` — Release automation (AMI, Bintray, Docker, docs publishing, metrics UI AppImage)
- `.for_maintainers/` — Release checklists and maintainer docs (all WallarooLabs-specific)
- `misc/` — wallaroo-up.sh installer, activate script, example-tester.bash, wallaroo-up-tester.bash
- `.github/` — Issue and PR templates
- `docs/proposals/` — Design doc (connector-protocol-v3.md)

### Root files (not moving)
- CHANGELOG.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md, CONTRIBUTORS, LICENSE, ROADMAP.md, SUPPORT.md, VERSION, wallaroo-logo.png

## Build System Details

The build system is a non-recursive make setup that will need significant rework for the new project.

### How it works now

- **`Makefile`** (root) sets control variables and includes `rules.mk`.
- **`rules.mk`** (~850 lines) is the engine:
  - Defines the `PONYC` function: runs `stable fetch` then `ponyc` with flags for debug, trace, spike, autoscale, clustering, resilience, and architecture.
  - Auto-discovers sub-Makefiles by recursing into subdirectories.
  - Auto-generates targets based on file presence: directories with `*.pony` files get `build-`, `test-`, `unit-tests-`, `integration-tests-`, `clean-` targets. Same for `*.exs` (Elixir) and `Dockerfile`.
  - Every Pony binary depends on `$(logging_lib_a)` (the C logging library).
  - Also has `MONHUBC`/`MONHUBR` functions for Elixir/Phoenix monitoring hub builds.
- **Sub-Makefiles** follow a pattern: include root Makefile (which includes rules.mk), set control flags (enable/disable pony/elixir/docker/recurse), then include rules.mk. Include-guard pattern prevents double evaluation.
- Uses `pony stable` (predecessor to `corral`) — all `bundle.json` files use stable format with local paths.

### Key concerns for new project

1. **Dependency manager**: Uses `stable` with `bundle.json`, not `corral`. All dependency files need conversion.
2. **Monorepo coupling**: Target names are computed relative to `$(abs_wallaroo_dir)`. Path assumptions are baked throughout.
3. **Elixir/Docker cruft**: Large portions of rules.mk handle Elixir builds and Docker image creation — not needed for Pony-only project.
4. **Logging library dependency**: The C logging library build (`cc` + `ar`) and its role as a prerequisite for all Pony builds needs to be preserved.
5. **Compile flags**: The conditional `-D` flags (autoscale, clustering, resilience, trace, spike) are important framework features that need to be carried forward.

## Work Items for New Project

1. **Build system** — Replace stable-based non-recursive make with corral-based build. Preserve C logging lib build and conditional compile flags.
2. **Pony test app rewrites** — Write Pony versions of: dummy_python, parallel_classifier, topology_tester, and the Python versions of multi_partition_detector, window_detector. Also rewrite aloc_sink tests and Python performance test apps.
3. **Conformance test updates** — Replace Python app references with Pony app references in test files. Write Pony apps for topology and CLI test categories.
4. **Documentation cleanup** — Drop Python/Go sections from Hugo docs site. Update operators manual examples to use Pony binary names instead of machida.
5. **Book rework** — Rewrite getting-started guides for Pony (currently Python-focused, using as templates).
6. **Kafka code** — Kafka source/sink code in core library and celsius-kafka example are kept for now. Decision on long-term retention TBD.
