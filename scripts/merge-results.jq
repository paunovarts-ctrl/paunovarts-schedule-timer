# Merges two results files after a push race (26 Oct): .[0] is the newest remote file, .[1] is this run's answer.
# This run's entry wins, except that a post the remote already published (it has a mediaId) never loses that to an
# entry without one: a lost "published" record is how a post would go out twice. Log lines are joined, no repeats.
.[0] as $r | .[1] as $o
| ($o | del(.posts, .log))
  + { posts: (reduce ((($r.posts // {}) + ($o.posts // {})) | keys[]) as $k ({};
        .[$k] = (if (($r.posts[$k].mediaId // "") != "") and (($o.posts[$k].mediaId // "") == "")
                 then $r.posts[$k] else ($o.posts[$k] // $r.posts[$k]) end))),
      log: (($r.log // []) + (($o.log // []) - ($r.log // []))) }
