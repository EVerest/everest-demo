#!/usr/bin/env python
# SPDX-License-Identifier: Apache-2.0
# Copyright 2023 Contributors to EVerest

import logging
import pytest
import queue
import threading
import time

from everest.framework import Module, RuntimeSession
from everest.testing.core_utils.everest_core import EverestCore, Requirement
from everest.testing.core_utils.fixtures import *


class ProbeModule:
    def __init__(self, session: RuntimeSession):
        m = Module("probe", session)
        self._setup = m.say_hello()

        # subscribe to session events
        evse_manager_ff = self._setup.connections["connector_1"][0]
        m.subscribe_variable(
            evse_manager_ff, "session_event", self._handle_evse_manager_event
        )

        self._msg_queue = queue.Queue()

        self._ready_event = threading.Event()
        self._mod = m
        m.init_done(self._ready)

    def _ready(self):
        self._ready_event.set()

    def _handle_evse_manager_event(self, args):
        self._msg_queue.put(args)

    def _parse_event_dict(self, expected_events: dict, args: dict) -> bool:
        keys = expected_events[0].keys()
        if len(keys) == 1:
            key = list(keys)[0]
            if key == "error":
                expected_error_code = expected_events[0][key]
                error_code = args[key]["error_code"]
                return expected_error_code == error_code
            else:
                logging.error(f"Key: {key} not supported")
        else:
            logging.warning("Not supporting multiple keys")

    def _pool_for_expected_events(
        self, expected_events: list[str], end_of_time: float
    ) -> bool:
        while len(expected_events) > 0:
            time_left = end_of_time - time.time()

            if time_left < 0:
                return False
            try:
                args = self._msg_queue.get(timeout=time_left)
                if type(expected_events[0]) is str:
                    if expected_events[0] == args["event"]:
                        expected_events.pop(0)
                elif type(expected_events[0]) is dict:
                    if self._parse_event_dict(expected_events, args):
                        expected_events.pop(0)
            except queue.Empty:
                return False

        return True

    def test(
        self, charging_session_cmd: dict, expected_events: list[str], timeout: float
    ) -> bool:
        end_of_time = time.time() + timeout

        if not self._ready_event.wait(timeout):
            return False

        # fetch fulfillment
        car_sim_ff = self._setup.connections["test_control"][0]

        # enable simulator
        self._mod.call_command(car_sim_ff, "enable", {"value": True})

        # start charging simulation
        logging.info(charging_session_cmd["value"])
        self._mod.call_command(
            car_sim_ff, "executeChargingSession", charging_session_cmd
        )

        return self._pool_for_expected_events(expected_events, end_of_time)


@pytest.mark.asyncio
async def test_000_startup_check(everest_core: EverestCore):
    logging.info(">>>>>>>>> test_000_startup_check <<<<<<<<<")
    everest_core.start()


@pytest.mark.everest_core_config("config-sil.yaml")
@pytest.mark.asyncio
async def test_001_start_test_module(everest_core: EverestCore):
    logging.info(">>>>>>>>> test_001_start_test_module <<<<<<<<<")

    test_connections = {
        "test_control": [Requirement("car_simulator", "main")],
        "connector_1": [Requirement("connector_1", "evse")],
    }

    everest_core.start(standalone_module="probe", test_connections=test_connections)
    logging.info("everest-core ready, waiting for probe module")

    session = RuntimeSession(
        str(everest_core.prefix_path), str(everest_core.everest_config_path)
    )

    probe = ProbeModule(session)

    if everest_core.status_listener.wait_for_status(10, ["ALL_MODULES_STARTED"]):
        everest_core.all_modules_started_event.set()
        logging.info("set all modules started event...")
    charging_session_cmd = {
        "value": "sleep 1;iec_wait_pwr_ready;sleep 1;draw_power_regulated 16,3;sleep 5"
    }
    expected_events = ["TransactionStarted", "ChargingStarted"]

    assert probe.test(charging_session_cmd, expected_events, 20)


@pytest.mark.asyncio
async def test_000_demo_run(everest_core: EverestCore):
    logging.info(">>>>>>>>> test_000_demo_run <<<<<<<<<")

    test_connections = {
        "test_control": [Requirement("car_simulator", "main")],
        "connector_1": [Requirement("connector_1", "evse")],
    }

    everest_core.start(standalone_module="probe", test_connections=test_connections)

    logging.info("everest-core ready, waiting for probe module")

    session = RuntimeSession(
        str(everest_core.prefix_path), str(everest_core.everest_config_path)
    )

    probe = ProbeModule(session)

    if everest_core.status_listener.wait_for_status(10, ["ALL_MODULES_STARTED"]):
        everest_core.all_modules_started_event.set()
        logging.info("set all modules started event...")

    charging_session_cmd = {
        "value": "sleep 1;iec_wait_pwr_ready;sleep 1;draw_power_regulated 16,3;sleep 5;pause;sleep 5;diode_fail;sleep 5"
    }
    expected_events = [
        "TransactionStarted",
        "ChargingStarted",
        "ChargingPausedEV",
        {"error": "CarDiodeFault"},
    ]

    assert probe.test(charging_session_cmd, expected_events, 20)
