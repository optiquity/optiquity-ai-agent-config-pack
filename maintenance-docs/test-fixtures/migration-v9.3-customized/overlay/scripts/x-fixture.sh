#!/usr/bin/env bash
# Project-only script (FIXTURE-MARKER-PROJECT-ONLY).
#
# Confirms that scripts/x-*.sh files are preserved by the migration's S3
# stage rather than overwritten or deleted. The migration script must
# leave x-*.sh siblings in place per OQ-6(b).
echo "fixture project-only script ran"
