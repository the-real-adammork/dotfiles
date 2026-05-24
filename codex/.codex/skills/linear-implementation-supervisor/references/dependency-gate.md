# Real Dependency Gate

Real dependencies required by the implementation plan, task wording, requirements, technical design, or production/dev behavior are mandatory for task verification. Do not downgrade them to optional smoke-test notes, optional review-packet commands, or "nice to have" follow-ups.

The agent team must try to satisfy required real dependencies before blocking:

- start local services, emulators, databases, queues, or test containers when available;
- run existing setup, seed, migration, or fixture-loading scripts;
- use already-authenticated CLIs or environment variables without printing secrets;
- create temporary test tenants, resources, topics, buckets, schemas, or records when the repo's tooling supports it;
- document cleanup for any created resources.

Block the task instead of moving it to human review when a required real dependency cannot be satisfied because:

- credentials, account access, private keys, paid services, allowlists, or approvals are missing;
- the correct service/environment is ambiguous and product or engineering steering is needed;
- provisioning would mutate production data or create cost/risk without explicit approval;
- the required real service is unavailable and no approved local/test substitute exists.

When blocking, assign the Linear issue to the configured admin user, set it to `status_blocked`, update SQLite, and leave one compact Linear comment with:

- the exact dependency or decision needed;
- what the agent already tried;
- the command or setup step the human should run, if known;
- where the workflow should resume after the dependency is available.

Mocks, fixtures, recordings, and fakes are allowed only for task requirements that explicitly call for isolated/unit coverage, hard-to-trigger error paths, or as an additional fast test beside mandatory real-service verification. They do not satisfy a task that requires real service, real network, real database, or real-data proof unless the implementation plan explicitly places that real proof in a later task and the current task does not claim completion of the real integration.

Workers and reviewers must explicitly disclose every test boundary mode:

- `real-service`, `local-service`, `test-container`, `real-network`, or `real-data`;
- `fixture`, `recording`, `mock`, or `fake`.

When fixtures, recordings, mocks, or fakes are used, the supervisor must record why they are acceptable now and point to the later implementation-plan task that converts the boundary to a real service/data path or adds a larger real end-to-end test. If no later task exists and real coverage is required, block the task or update upcoming plans through the consistency workflow before proceeding.
