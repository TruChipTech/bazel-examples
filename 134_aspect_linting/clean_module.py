import logging

LOG = logging.getLogger(__name__)


def compute(value):
    LOG.info("computing")
    return value * 2
