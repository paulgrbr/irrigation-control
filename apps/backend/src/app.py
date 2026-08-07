#!/usr/bin/env python3
import atexit
import os
import threading
import time

from flask import Flask, jsonify
from periphery import GPIO
from smbus2 import SMBus

RELAY_TIME_SECONDS = 0.5
RELAY_PAUSE_SECONDS = 0.3
LCD_WIDTH = 20
LCD_BACKLIGHT = 0x08
LCD_ENABLE_BIT = 0x04
LCD_REGISTER_SELECT = 0x01
LCD_LINE_ADDRESSES = (0x80, 0xC0, 0x94, 0xD4)


RELAYS = (
    (17, "braun"),
    (27, "rot"),
    (22, "orange"),
    (10, "gelb"),
    (5, "gruen"),
    (9, "blau"),
    (6, "lila"),
    (11, "grau"),
)


class LCD:
    def __init__(self) -> None:
        self.bus_id = int(os.environ.get("LCD_I2C_BUS", "1"))
        self.address = int(os.environ.get("LCD_I2C_ADDR", "0x27"), 0)
        self.disabled = os.environ.get("LCD_DISABLE", "0") == "1"
        self.bus = None

    def _write_byte(self, value: int) -> None:
        self.bus.write_byte(self.address, value)

    def _pulse_enable(self, value: int) -> None:
        self._write_byte(value | LCD_ENABLE_BIT)
        time.sleep(0.0005)
        self._write_byte(value & ~LCD_ENABLE_BIT)
        time.sleep(0.0001)

    def _write_4bit(self, value: int, mode: int = 0) -> None:
        upper = mode | (value & 0xF0) | LCD_BACKLIGHT
        lower = mode | ((value << 4) & 0xF0) | LCD_BACKLIGHT
        self._write_byte(upper)
        self._pulse_enable(upper)
        self._write_byte(lower)
        self._pulse_enable(lower)

    def _write_init_nibble(self, nibble: int) -> None:
        value = (nibble & 0xF0) | LCD_BACKLIGHT
        self._write_byte(value)
        self._pulse_enable(value)

    def _command(self, value: int) -> None:
        self._write_4bit(value)

    def _initialize(self) -> None:
        time.sleep(0.05)
        self._write_init_nibble(0x30)
        time.sleep(0.005)
        self._write_init_nibble(0x30)
        time.sleep(0.0002)
        self._write_init_nibble(0x30)
        self._write_init_nibble(0x20)
        self._command(0x28)
        self._command(0x0C)
        self._command(0x06)

    def write(self, *lines: str) -> None:
        if self.disabled:
            return

        try:
            if self.bus is None:
                self.bus = SMBus(self.bus_id)
                self._initialize()
            for line_number, text in enumerate(lines[:4]):
                self._command(LCD_LINE_ADDRESSES[line_number])
                for character in text.encode("ascii", errors="replace")[:LCD_WIDTH].ljust(LCD_WIDTH):
                    self._write_4bit(character, LCD_REGISTER_SELECT)
        except OSError as error:
            print(f"LCD unavailable: {error}", flush=True)
            self.close()

    def close(self) -> None:
        if self.bus is not None:
            self.bus.close()
            self.bus = None


app = Flask(__name__)
lcd = LCD()
status = {"state": "starting", "current_relay": None, "error": None}
relay_devices = []


def update_display(line3: str, line4: str) -> None:
    lcd.write("Willkommen", "Irrigation Control", line3, line4)


def run_relay_test() -> None:
    try:
        update_display("Relais-Test", "Bitte warten")
        for gpio, _ in RELAYS:
            device = GPIO("/dev/gpiochip0", gpio, "out")
            device.write(True)
            relay_devices.append(device)

        for number, ((gpio, color), device) in enumerate(zip(RELAYS, relay_devices), start=1):
            status["current_relay"] = number
            update_display(f"Relais {number}/{len(RELAYS)} EIN", f"GPIO {gpio} {color}")
            device.write(False)
            time.sleep(RELAY_TIME_SECONDS)
            device.write(True)
            time.sleep(RELAY_PAUSE_SECONDS)

        status["state"] = "ready"
        status["current_relay"] = None
        update_display("Relais-Test fertig", "System bereit")
    except Exception as error:
        status["state"] = "failed"
        status["error"] = str(error)
        update_display("Relais-Test Fehler", "Pruefe GPIO")
        print(f"Relay test failed: {error}", flush=True)
    finally:
        for device in relay_devices:
            device.write(True)


@atexit.register
def close_devices() -> None:
    for device in relay_devices:
        device.write(True)
        device.close()
    lcd.close()


@app.get("/")
def index():
    return jsonify(message="Willkommen bei Irrigation Control", **status)


@app.get("/health")
def health():
    http_status = 200 if status["state"] == "ready" else 503
    return jsonify(**status), http_status


if __name__ == "__main__":
    test_thread = threading.Thread(target=run_relay_test, name="relay-test", daemon=True)
    test_thread.start()
    app.run(host="0.0.0.0", port=8080)