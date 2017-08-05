from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import numpy as np
import pandas as pd

def roll_fun(x, size, fun=np.mean, reverse=False):
    y = np.copy(x)
    n = len(x)
    size = min(size, n)

    if size <= 1:
        return x

    for i in xrange(size):
        y[i] = fun(x[0:(i + 1)])
    for i in xrange(size, n):
        y[i] = fun(x[(i - size + 1):(i + 1)])
    return y


def carry_forward_if(x, is_true):
    """Locomote forward object x[i] if is_true[i].
        remain x untouched before first pos of truth.
    """
    for i in xrange(len(x)):
        if is_true[i]:
            cargo = x[i]
        if cargo is not None:
            x[i] = cargo
    return x


def carry_backward_if(x, is_true):
    """Locomote backward object x[i] if is_true[i].
        remain x untouched after last pos of truth.
    """
    for i in xrange(reversed(len(x))):
        if is_true[i]:
            cargo = x[i]
        if cargo is not None:
            x[i] = cargo
    return x


def steps_since_true_minimal(is_event):
    """(Time) since event over discrete (padded) events.
    """
    n = len(is_event)
    z = -1  # at the latest on step before
    x = np.int32(is_event)
    for i in xrange(n):
        if is_event[i]:
            z = i
        x[i] = i - z
    return x


def steps_to_true_minimal(is_event):
    """(Time) to event for discrete (padded) events.
    """
    n = len(is_event)
    z = n  # at the earliest on step after
    x = np.int32(is_event)
    for i in reversed(xrange(n)):
        if is_event[i]:
            z = i
        x[i] = z - i
    return x


def get_tte_discrete(is_event, t_elapsed=None):
    n = len(is_event)
    tte = np.int32(is_event)
    stepsize = 1
    if t_elapsed is None:
        t_elapsed = xrange(n)

    t_next = t_elapsed[-1] + stepsize
    for i in reversed(xrange(n)):
        if is_event[i]:
            t_next = t_elapsed[i]
        tte[i] = t_next - t_elapsed[i]
    return tte


def get_tte_continuous(is_event, t_elapsed):
    n = len(is_event)
    if t_elapsed is None:
        t_elapsed = np.int32(xrange(n))

    t_next = t_elapsed[-1]
    # lazy initialization to autoinit if difftime
    tte = t_elapsed - t_next
    for i in reversed(xrange(n)):
        tte[i] = t_next - t_elapsed[i]
        if is_event[i]:
            t_next = t_elapsed[i]
    return tte


def get_tte(is_event, discrete_time, t_elapsed=None):
    if discrete_time:
        return get_tte_discrete(is_event, t_elapsed)
    else:
        return get_tte_continuous(is_event, t_elapsed)


def get_tse(is_event, t_elapsed=None):
    if t_elapsed is not None:
        t_elapsed = t_elapsed.max() - t_elapsed[::-1]

    return get_tte_continuous(is_event[::-1], t_elapsed)[::-1]


def get_is_not_censored(is_event, discrete_time=True):
    """ Calculates non-censoring indicator u
    """
    n = len(is_event)
    is_not_censored = np.copy(is_event)

    if discrete_time:
        # Last obs is conditionally censored
        event_seen = is_event[-1]
        for i in reversed(xrange(n)):
            if is_event[i] and not event_seen:
                event_seen = is_event[i]
            is_not_censored[i] = event_seen
    else:
        # Last obs is always censored
        event_seen = False
        for i in reversed(xrange(n)):
            is_not_censored[i] = event_seen
            if is_event[i] and not event_seen:
                event_seen = is_event[i]

    return is_not_censored
