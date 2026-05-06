# scripts/tests/fixtures/tracker-provider/stub-backend.sh
#
# A minimal "stub" tracker backend used ONLY by tracker-provider-test.sh
# to exercise the dispatcher's multi-backend extensibility.
#
# Every op records its name + args into a global $STUB_CALLS log and
# returns a canonical JSON shape. This lets the structural test
# verify that:
#   1. The dispatcher routes _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
#      to tracker_provider_stub_*().
#   2. Adding a new backend does not require any change to tracker-
#      provider.sh other than a single case in the switch.
#
# This file is sourced by tracker-provider-test.sh under the stub
# test only; never sourced by production code.
#
# Do NOT add a shebang — sourced.

STUB_CALLS=""

_stub_record() {
    STUB_CALLS="$STUB_CALLS|$*"
}

tracker_provider_stub_list()             { _stub_record "list" "$@";             echo '{"items":[],"next_cursor":null}'; }
tracker_provider_stub_get()              { _stub_record "get" "$@";              echo '{"id":"'"$1"'","number":"'"$1"'"}'; }
tracker_provider_stub_search()           { _stub_record "search" "$@";           echo '{"items":[],"next_cursor":null}'; }
tracker_provider_stub_create()           { _stub_record "create" "$@";           echo '{"id":"99","number":"99","url":"stub://99"}'; }
tracker_provider_stub_update()           { _stub_record "update" "$@";           echo '{"id":"'"$1"'","updated":true}'; }
tracker_provider_stub_close()            { _stub_record "close" "$@";            echo '{"id":"'"$1"'","state":"closed"}'; }
tracker_provider_stub_reopen()           { _stub_record "reopen" "$@";           echo '{"id":"'"$1"'","state":"open"}'; }
tracker_provider_stub_comment()          { _stub_record "comment" "$@";          echo '{"id":"'"$1"'","comment_url":"stub://c"}'; }
tracker_provider_stub_set_labels()       { _stub_record "set_labels" "$@";       echo '{"id":"'"$1"'","labels":'"$2"'}'; }
tracker_provider_stub_set_assignee()     { _stub_record "set_assignee" "$@";     echo '{"id":"'"$1"'","assignees":'"$2"'}'; }
tracker_provider_stub_set_milestone()    { _stub_record "set_milestone" "$@";    echo '{"id":"'"$1"'","milestone":"'"$2"'"}'; }
tracker_provider_stub_link()             { _stub_record "link" "$@";             echo '{"id":"'"$1"'","linked_to":"'"$2"'","kind":"'"$3"'"}'; }
tracker_provider_stub_unlink()           { _stub_record "unlink" "$@";           echo '{"id":"'"$1"'","unlinked_from":"'"$2"'","kind":"'"$3"'"}'; }
tracker_provider_stub_sub_issue_create() { _stub_record "sub_issue_create" "$@"; echo '{"parent_id":"'"$1"'","child_id":"99"}'; }
tracker_provider_stub_sub_issue_list()   { _stub_record "sub_issue_list" "$@";   echo '[]'; }
tracker_provider_stub_sub_issue_unlink() { _stub_record "sub_issue_unlink" "$@"; echo '{"parent_id":"'"$1"'","child_id":"'"$2"'","unlinked":true}'; }
tracker_provider_stub_capabilities()     { _stub_record "capabilities";          echo '{"backend_name":"stub","raw_escape_hatch":false}'; }
tracker_provider_stub_raw()              { _stub_record "raw" "$@";              echo '{}'; }
