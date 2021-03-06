import time

__all__ = ("Cooldown",)

cdef double NaN = float("nan")

cdef class Cooldown:
    cdef public signed long long rate
    cdef public double per
    cdef public double _window
    cdef public signed long long _tokens
    cdef public double _last
    cdef public object type

    def __init__(self, signed long long rate, double per, object type):
        if not callable(type):
            raise TypeError("Cooldown type must be a BucketType or callable")

        self.rate = rate
        self.per = per
        self.type = type

        self._window = 0.0
        self._tokens = rate
        self._last = 0.0

    cpdef signed long long get_tokens(self, double current = NaN):
        if not current:
            current = time.time()

        cdef signed long long tokens = self._tokens

        if current > self._window + self.per:
            tokens = self.rate

        return tokens

    cpdef double get_retry_after(self, double current = NaN):
        current = current or time.time()
        cdef signed long long tokens = self.get_tokens(current)

        if tokens == 0:
            return self.per - (current - self._window)

        return 0.0

    cpdef double update_rate_limit(self, double current = NaN):
        current = current or time.time()
        self._last = current

        self._tokens = self.get_tokens(current)

        if self._tokens == self.rate:
            self._window = current

        if self._tokens == 0:
            return self.per - (current - self._window)

        self._tokens -= 1

        if self._tokens == 0:
            self._window = current

    cpdef void reset(self):
        self._tokens = self.rate
        self._last = 0.0

    cpdef Cooldown copy(self):
        return Cooldown(self.rate, self.per, self.type)

    def __repr__(self):
        return f"<Cooldown rate: {self.rate} per: {self.per} window: {self._window} tokens: {self._tokens}>"
