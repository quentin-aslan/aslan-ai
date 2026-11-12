"""python3 test_server.py  -> offline checks (protocol + rules, fake Things).
THINGS_LIVE=1 python3 test_server.py  -> also a read-only smoke test against the real Things app."""
import datetime
import json
import os
import subprocess
import sys

import server

TODAY = datetime.date.today().isoformat()


class FakeThings:
    def __init__(self, today_count=0):
        self.today_count, self.calls, self.moves = today_count, [], []

    def __call__(self, action, **req):
        self.calls.append((action, req))
        if action == "count_today":
            return {"count": self.today_count}
        if action == "list":
            return {"items": [{"id": "AAAAAAAAAAAA1"}]}
        if action == "add":
            return {"id": "BBBBBBBBBBBB2", "title": req["title"], "tags": req["tags"], "notes": req["notes"]}
        return {"id": req.get("id"), "when": None}


def call(session, name, args, mid=1):
    r = server.handle(session, {"jsonrpc": "2.0", "id": mid, "method": "tools/call",
                                "params": {"name": name, "arguments": args}})
    return r["result"]


def offline():
    s = server.Session(backend=FakeThings())
    init = server.handle(s, {"jsonrpc": "2.0", "id": 0, "method": "initialize", "params": {"protocolVersion": "2099-01-01"}})
    assert init["result"]["protocolVersion"] == server.VERSIONS[0]
    assert "tools" in init["result"]["capabilities"]
    assert server.handle(s, {"jsonrpc": "2.0", "method": "notifications/initialized"}) is None
    assert server.handle(s, {"jsonrpc": "2.0", "id": 2, "method": "nope"})["error"]["code"] == -32601
    names = [t["name"] for t in server.handle(s, {"jsonrpc": "2.0", "id": 3, "method": "tools/list"})["result"]["tools"]]
    assert not any("delete" in n for n in names), names
    assert server.handle(s, {"jsonrpc": "2.0", "id": 4, "method": "tools/call", "params": {"name": "things_delete"}})["error"]

    full = server.Session(backend=FakeThings(today_count=9), mover=lambda *a: None)
    r = call(full, "things_add", {"title": "x", "when": "today"})
    assert r["isError"] and "cap" in r["content"][0]["text"]
    r = call(full, "things_add", {"title": "x", "when": TODAY})
    assert r["isError"]

    fake = FakeThings()
    ok = server.Session(backend=fake, mover=lambda i, t: fake.moves.append((i, t)))
    assert call(ok, "things_add", {"title": "⏳ Papa : diplôme"})["isError"]
    r = call(ok, "things_add", {"title": "Papa : diplôme é", "waiting_until": "2026-11-14", "source": "WhatsApp"})
    body = json.loads(r["content"][0]["text"])
    assert body["title"].startswith("⏳ ") and "En attente" in body["tags"] and "Source: WhatsApp" in body["notes"]
    assert call(ok, "things_complete", {"id": "ZZZZZZZZZZZZ9"})["isError"]  # never listed
    call(ok, "things_list", {"list": "today"})
    assert not call(ok, "things_complete", {"id": "AAAAAAAAAAAA1"})["isError"]
    assert call(ok, "things_schedule", {"id": "AAAAAAAAAAAA1", "when": "evening"})["isError"]

    budget = server.Session(backend=FakeThings(), mover=lambda *a: None)
    for i in range(server.WRITE_BUDGET):
        assert not call(budget, "things_add", {"title": "t%d" % i})["isError"]
    assert "budget" in call(budget, "things_add", {"title": "one more"})["content"][0]["text"]
    print("offline: ok")


def live():
    p = subprocess.Popen([sys.executable, os.path.join(server.HERE, "server.py")], stdin=subprocess.PIPE,
                         stdout=subprocess.PIPE, text=True, encoding="utf-8")
    msgs = [{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-06-18"}},
            {"jsonrpc": "2.0", "method": "notifications/initialized"},
            {"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "things_list", "arguments": {"list": "today"}}}]
    out, _ = p.communicate("".join(json.dumps(m) + "\n" for m in msgs), timeout=60)
    replies = [json.loads(l) for l in out.splitlines()]
    assert [r["id"] for r in replies] == [1, 2], replies
    assert not replies[1]["result"]["isError"], replies[1]
    print("live: ok,", json.loads(replies[1]["result"]["content"][0]["text"])["count"], "open to-dos in Today")


if __name__ == "__main__":
    offline()
    if os.environ.get("THINGS_LIVE"):
        live()
