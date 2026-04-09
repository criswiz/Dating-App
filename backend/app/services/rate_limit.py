from time import time
from collections import defaultdict, deque


class SlidingWindowRateLimiter:
    def __init__(self, max_requests: int, window_seconds: int):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._history = defaultdict(deque)

    def allow(self, actor_key: str) -> bool:
        now = time()
        history = self._history[actor_key]
        cutoff = now - self.window_seconds
        while history and history[0] < cutoff:
            history.popleft()
        if len(history) >= self.max_requests:
            return False
        history.append(now)
        return True

    def reset(self) -> None:
        self._history.clear()


interaction_limiter = SlidingWindowRateLimiter(max_requests=60, window_seconds=60)
