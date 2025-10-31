#!/usr/bin/env python3
import asyncio
import os
import sys
from typing import List, Tuple


def parse_listen(addr: str) -> Tuple[str, int]:
    # Expect IPv4 "host:port"; default port 162
    if not addr:
        return ("0.0.0.0", 162)
    if ":" in addr:
        host, port = addr.rsplit(":", 1)
        return (host or "0.0.0.0", int(port))
    return (addr, 162)


def parse_targets(lst: str) -> List[Tuple[str, int]]:
    targets: List[Tuple[str, int]] = []
    if not lst:
        return targets
    for raw in lst.split(","):
        item = raw.strip()
        if not item:
            continue
        if ":" in item:
            host, port = item.rsplit(":", 1)
            targets.append((host.strip(), int(port)))
        else:
            targets.append((item, 162))
    return targets


class FanoutProtocol(asyncio.DatagramProtocol):
    def __init__(self, loop: asyncio.AbstractEventLoop, targets: List[Tuple[str, int]], verbose: bool):
        self.loop = loop
        self.targets = targets
        self.transport = None  # type: ignore
        self.verbose = verbose

    def connection_made(self, transport):
        self.transport = transport
        if self.verbose:
            sockname = transport.get_extra_info("sockname")
            print(f"[fanout] Listening on {sockname}")
            print(f"[fanout] Targets: {', '.join(f'{h}:{p}' for h,p in self.targets)}")

    def datagram_received(self, data: bytes, addr):
        # Fan out to all targets
        if self.verbose:
            try:
                src = f"{addr[0]}:{addr[1]}"
            except Exception:
                src = str(addr)
            print(f"[fanout] Received {len(data)} bytes from {src}")
        for host, port in self.targets:
            try:
                self.transport.sendto(data, (host, port))
                if self.verbose:
                    print(f"[fanout] Sent {len(data)} bytes to {host}:{port}")
            except Exception as e:
                if self.verbose:
                    print(f"[fanout] Send error to {host}:{port}: {e}", file=sys.stderr)


async def main():
    listen_addr = os.environ.get("LISTEN_ADDR", "0.0.0.0:162")
    forward_list = os.environ.get("FORWARD_LIST", "")
    verbose = os.environ.get("FANOUT_VERBOSE", "0") not in ("0", "false", "False", "no", "NO")

    host, port = parse_listen(listen_addr)
    targets = parse_targets(forward_list)
    if not targets:
        print("[fanout] No targets in FORWARD_LIST; exiting", file=sys.stderr)
        sys.exit(1)

    if verbose:
        print(f"[fanout] Starting: listen={host}:{port} targets={', '.join(f'{h}:{p}' for h,p in targets)}")

    loop = asyncio.get_event_loop()
    try:
        transport, protocol = await loop.create_datagram_endpoint(
            lambda: FanoutProtocol(loop, targets, verbose), local_addr=(host, port)
        )
    except Exception as e:
        print(f"[fanout] Failed to bind {host}:{port}: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        await asyncio.Future()  # run forever
    finally:
        transport.close()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
